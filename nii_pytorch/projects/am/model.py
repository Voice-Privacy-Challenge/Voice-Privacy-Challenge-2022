#!/usr/bin/env python
"""
model.py
"""
from __future__ import absolute_import
from __future__ import print_function

import sys
import numpy as np

import torch
import torch.nn as torch_nn
import torch.nn.functional as torch_nn_func

import sandbox.block_nn as nii_nn
import sandbox.util_frontend as nii_front_end
import core_scripts.other_tools.debug as nii_debug
import core_scripts.data_io.seq_info as nii_seq_tk

__author__ = "Xin Wang"
__email__ = "wangxin@nii.ac.jp"
__copyright__ = "Copyright 2020, Xin Wang"


##############
## Model Components
##############

class GatedActWithNoise(torch_nn.Module):
    """GatedActWithNoise(in_dim, noise_ratio=1.0)

    Args
    ----
      in_dim: int, dimension of input features per frame
      noise_ratio: float, scaling factor on uniform noise

    This component does output = GatedActWithNoise(input)
    
    output = tanh(input) * sigmoid(noise)
    where * denotes element-wise product, noise is from U[-ratio, ratio]
    """
    def __init__(self, in_dim, noise_ratio=1.0):
        super(GatedActWithNoise, self).__init__()
        self.noise_ratio = noise_ratio
        return
    def forward(self, input_data):
        """ output = GatedActWithNoise(input)
        This does output = tanh(input) * sigmoid(noise)
        
        input
        -----
          input_data: tensor, (batch, length, in_dim)
        
        output
        ------
          output_data: tensor, same shape as input_data
        """
        noise = torch.rand_like(input_data) * self.noise_ratio * 2
        noise = noise - self.noise_ratio
        return torch.tanh(input_data) * torch.sigmoid(noise)


class PostNetCNNLayer(torch_nn.Module):
    """PostNetCNNLayer(in_dim, kernel_s)
    
    Args
    ----
      in_dim, int, dimension of input features per frame
      kernel_s: int, kernel size of CNN
    
    This component does output = cnn1d_causal(input).
    It does not change the shape of input tensor.
    The CNN is causal.
    """
    def __init__(self, in_dim, kernel_s):
        super(PostNetCNNLayer, self).__init__()
        self.padsize = kernel_s - 1
        self.m_cnn = torch_nn.Conv1d(in_dim, in_dim, kernel_s, 1, self.padsize)
        return

    def forward(self, x):
        """ output = PostNetCNNLayer(input)
        This does output = cnn1d_causal(input). 
        
        input
        -----
          input_data: tensor, (batch, in_dim, length)
        
        output
        ------
          output_data: tensor, (batch, in_dim, length)

        Conv1d is conducted along the last dimension
        """
        # pass through CNN and take the causal output
        x_cnn = self.m_cnn(x)[:, :, :-self.padsize]
        return x_cnn

class CombineFeedBack(torch_nn.Module):
    """CombineFeedBack(in_dim, out_dim, scale_input=0.1)
    
    Args
    ----
      in_dim: int, dimension of input features per frame
      out_dim: int, dimension of target features, i.e., fedback features.
      scale_input: float, scaling factor on input

    This component combines feedback features with feedforwad features
    """
    def __init__(self, in_dim, out_dim, scale_input=0.1):
        super(CombineFeedBack, self).__init__()
        
        self.m_gate = GatedActWithNoise(out_dim)
        self.m_fb_trans = torch_nn.Sequential(
            torch_nn.Linear(out_dim, out_dim),
            torch_nn.Linear(out_dim, out_dim)
        )
        self.m_scale_input = scale_input
        return

    def forward(self, input_hid, feedback_data):
        """ output = CombineFeedBack(input, feedback)
        
        input
        -----
          input_data: tensor, (batch, length, in_dim)
          feedback: tensor, (batch, length, out_dim)
        
        output
        ------
          output_data: tensor, (batch, length, in_dim + out_dim)
        
        fb_tmp = FC(FC(GatedActWithNoise(feedback_data)))
        output = concatenate([input_data, fb_tmp])
        
        FC is conducted on the last dimension of feedback_data.
        """
        # do some regularization on feedback data
        fb_tmp = self.m_gate(feedback_data * self.m_scale_input)
        fb_tmp = self.m_fb_trans(fb_tmp)
        # concatenate the input hidden feature with feedback data
        return torch.cat([input_hid, fb_tmp], dim=2)

class PostNet(torch_nn.Module):
    """PostNet(out_dim)

    Args:
    -----
      out_dim: int, dimension of the input features


    This wrapper consists of PostNetCNNLayer and GatedActWithNoise.
    It conducts output = PostNet(input), where
    input and output have the same tensor shape (batch, length, out_dim)
    """
    def __init__(self, out_dim):
        super(PostNet, self).__init__()
        
        self.m_post = torch_nn.Sequential(
            PostNetCNNLayer(out_dim, 5),
            GatedActWithNoise(out_dim),
            PostNetCNNLayer(out_dim, 5),
            GatedActWithNoise(out_dim),            
            PostNetCNNLayer(out_dim, 5),
            GatedActWithNoise(out_dim),            
            PostNetCNNLayer(out_dim, 5),
            GatedActWithNoise(out_dim),            
            PostNetCNNLayer(out_dim, 5),
        )
        return

    def forward(self, input_x):
        """ output = PostNet(input)
        
        input
        -----
          input_data: tensor, (batch, length, out_dim)
        
        output
        ------
          output_data: tensor, (batch, length, out_dim)
        
        output = input + PostNetCNN(GatedNoise(... (input)))
        """
        return input_x + self.m_post(input_x.permute(0, 2, 1)).permute(0, 2, 1)


##########################
## Model definition
##########################

class Model(torch_nn.Module):
    """Full definition for the acoustic model
    This class will be called by main.py

    Args
    ----
      in_dim: int, dimension of input features per frame
              Here, it is = dim of PPG + dim of xvector + dim of F0
    
              input_tensor has shape (batch, length, in_dim)          
              Note that xvector will be duplicated to each frame

      out_dim: int, dimension of target feature per frame.
              Here, it is equal to the dimension of mel-spectrogram per frame
              Target feature has shape (batch, length, out_dim)
    
      args: arguments, given by the main.py
    
      prj_conf: configurations, given by the main.py
    
      mean_std: mean and std configurations of input and output features, 
                given by the main.py

    Two methods:
     1. loss = Model.forward(input, natural_mel), used for training
     2. generated_mel = Model.inference(input), used for inference
    
    The model looks like:

            |    part 1   |        part2          |  part3   |
    input -> FC(s), BLSTM -> cat() -> LSTM(s), FC -> PostNet -> target
                               ^                                  |
                               |- feedback -----------------------|

    """
    def __init__(self, in_dim, out_dim, args, prj_conf, mean_std=None):
        super(Model, self).__init__()

        ##### required part, no need to change #####
        # mean and std of input and output
        # They are used to do z-norm
        in_m, in_s, out_m, out_s = self.prepare_mean_std(in_dim,out_dim,\
                                                         args, mean_std)
        self.input_mean = torch_nn.Parameter(in_m, requires_grad=False)
        self.input_std = torch_nn.Parameter(in_s, requires_grad=False)
        self.output_mean = torch_nn.Parameter(out_m, requires_grad=False)
        self.output_std = torch_nn.Parameter(out_s, requires_grad=False)
        
        # a flag for debugging (by default False)
        #self.model_debug = False
        #self.validation = False
        #####
        
        # part 1
        # base transformation network
        # input -> FC(s), BLSTM
        self.m_base_hidsize = 512
        self.m_base_outsize = 256
        self.m_base = torch_nn.Sequential(
            torch_nn.Linear(in_dim, self.m_base_hidsize),
            torch_nn.Tanh(),
            torch_nn.Linear(self.m_base_hidsize, self.m_base_hidsize),
            torch_nn.Tanh(),
            torch_nn.LSTM(self.m_base_hidsize, self.m_base_outsize // 2, 
                          bidirectional=True, batch_first=True)
        )
        
        # part 2
        # combine with feedback output
        self.m_fdback = CombineFeedBack(self.m_base_outsize, out_dim)

        # after feedback network
        self.m_fb_proc_hidsize = 512
        self.m_fb_proc = torch_nn.Sequential(
            nii_nn.LSTMLayer(self.m_base_outsize+out_dim,
                             self.m_fb_proc_hidsize),
            nii_nn.LSTMLayer(self.m_fb_proc_hidsize, 
                             self.m_fb_proc_hidsize),
        )
        self.m_fb_proc_out = torch_nn.Linear(self.m_fb_proc_hidsize, out_dim)
        
        # part3
        # post network
        self.m_post = PostNet(out_dim)

        self.m_out_dim = out_dim
        self.m_loss = torch_nn.MSELoss()

        # done
        return
    
    def prepare_mean_std(self, in_dim, out_dim, args, data_mean_std=None):
        """ prepare mean and std for data processing
        This is required for the Pytorch project, but not relevant to this code
        """
        if data_mean_std is not None:
            in_m = torch.from_numpy(data_mean_std[0])
            in_s = torch.from_numpy(data_mean_std[1])
            out_m = torch.from_numpy(data_mean_std[2])
            out_s = torch.from_numpy(data_mean_std[3])
            if in_m.shape[0] != in_dim or in_s.shape[0] != in_dim:
                print("Input dim: {:d}".format(in_dim))
                print("Mean dim: {:d}".format(in_m.shape[0]))
                print("Std dim: {:d}".format(in_s.shape[0]))
                print("Input dimension incompatible")
                sys.exit(1)
            if out_m.shape[0] != out_dim or out_s.shape[0] != out_dim:
                print("Output dim: {:d}".format(out_dim))
                print("Mean dim: {:d}".format(out_m.shape[0]))
                print("Std dim: {:d}".format(out_s.shape[0]))
                print("Output dimension incompatible")
                sys.exit(1)
        else:
            in_m = torch.zeros([in_dim])
            in_s = torch.ones([in_dim])
            out_m = torch.zeros([out_dim])
            out_s = torch.ones([out_dim])
            
        return in_m, in_s, out_m, out_s
        
    def normalize_input(self, x):
        """ normalizing the input data
        This is required for the Pytorch project, but not relevant to this code
        """
        return (x - self.input_mean) / self.input_std

    def normalize_target(self, y):
        """ normalizing the target data
        This is required for the Pytorch project, but not relevant to this code
        """
        return (y - self.output_mean) / self.output_std

    def denormalize_output(self, y):
        """ denormalizing the generated output from network
        This is required for the Pytorch project, but not relevant to this code
        """
        return y * self.output_std + self.output_mean


    def _compute_loss(self, out, post, target):
        """loss = _compute_loss(out, post, target)
        We measure the loss using both the input and output of the postNet

        input
        -----
          out: tensor, (batch, length, out_dim), input to the postNet
          post: tensor, (batch, length, out_dim), output to the postNet
          target: tensor, (batch, length, out_dim), natural target
        
        output
        ------
          loss: scalar
        """
        return self.m_loss(out, target) + self.m_loss(post, target)

        
    def forward(self, x, target, fileinfo):
        """loss = forward(x, target, fileinfo)
        
        input
        -----
          x: tensor, (batch, length, in_dim), input to the acoustic model
          target: tensor, (batch, length, out_dim), natural target
          fileinfo: list of str, file information about each trial in the 
                    mini-batch. This is given by the script
        
        output
        ------
          loss: scalar, loss value
        """
        # get the file names in this mini-batch
        filenames = [nii_seq_tk.parse_filename(y) for y in fileinfo]
        # get the length of sequences in this mini-batch
        datalength = [nii_seq_tk.parse_length(y) for y in fileinfo]
        
        # normalize target
        target = self.normalize_target(target)
        with torch.no_grad():
            for idx, tmplen in enumerate(datalength):
                # the dummy padded 0 should be not normalzied
                target[idx, tmplen:] = 0

        # part1
        # transform input feature
        hid_x, _ = self.m_base(self.normalize_input(x))

        # part2
        # shift the feedback data by 1 time step
        target_ = torch.roll(target, 1, dims=1)
        # combine with feedback data
        hid_x = self.m_fdback(hid_x, target_)
        # transform
        out_x = self.m_fb_proc_out(self.m_fb_proc(hid_x))
        
        # part3
        # post transform
        post_x = self.m_post(out_x)

        return self._compute_loss(out_x, post_x, target)

    def inference(self, x):
        """output = forward(x)
        
        input
        -----
          x: tensor, (batch, length, in_dim), input to the acoustic model
        
        output
        ------
          output: tensor, (batch, length, out_dim), generated mel-spectrogram

        This method is similar to forward() but is used for generation.
        Particually, generation must be done in an auto-regressive manner.
        """        
        # part1
        # transform input feature
        hid_x, _ = self.m_base(self.normalize_input(x))

        # part2  
        bsize = x.shape[0]
        tlen = x.shape[1]
        # prepare the feedback
        buf = torch.zeros([bsize, tlen, self.m_out_dim], 
                          dtype=x.dtype, device=x.device)
        # auto-regressive generation (step-by-step)
        for idx in range(tlen):
            if idx == 0:
                z = self.m_fdback(hid_x[:, idx:idx+1], buf[:, 0:1])
            else:
                z = self.m_fdback(hid_x[:, idx:idx+1], buf[:, idx-1:idx])
            # through the multiple LSTM layers 
            for l in self.m_fb_proc:
                z = l.forward(z, idx)
            # through the FC layer
            buf[:, idx:idx+1] = self.m_fb_proc_out(z)

        # part3
        # post-net
        buf = self.m_post(buf)
        
        return buf


##########################
## Placce holder for Loss()
##########################

class Loss():
    """dummy wrapper. No need to change this.
    
    The script will load this Loss() and comptue a loss for each mini-batch.
    
    Loss_value = Loss.compute(outputs, target), where arguments automatically
    are taken from:
     1. outputs <- Model.forward()
     2. target  <- natural target
    This is useful when we want to evaluate the distance between output from
    the Model and the target, e.g.,: 
      loss_value = Loss.compute(outputs, target) = MSELoss(outputs, target)
    
    However, sometimes it is more convenient to compute the loss directly in 
    Model.forward(). In this case:
      outputs <- loss_value = Model.forward()
      loss_value = Loss.compute(outputs, target) = outputs

    Here we apply the second case. But a place holder Loss() must be created
    """
    def __init__(self, args):
        return

    def compute(self, outputs, target):
        return outputs

    
if __name__ == "__main__":
    print("Definition of model")

    
