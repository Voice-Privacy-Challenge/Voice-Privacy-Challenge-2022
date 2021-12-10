#!/usr/bin/env python
"""
main.py for project-NN-pytorch/projects

The default training/inference process wrapper
Requires model.py and config.py

Usage: $: python main.py [options]
"""
from __future__ import absolute_import
import os
import sys
import torch
import importlib

import core_scripts.data_io.default_data_io as nii_default_dset
import core_scripts.data_io.customize_dataset as nii_dset
import core_scripts.other_tools.display as nii_warn
import core_scripts.data_io.conf as nii_dconf
import core_scripts.other_tools.list_tools as nii_list_tool
import core_scripts.config_parse.config_parse as nii_config_parse
import core_scripts.config_parse.arg_parse as nii_arg_parse
import core_scripts.op_manager.op_manager as nii_op_wrapper
import core_scripts.nn_manager.nn_manager as nii_nn_wrapper
import core_scripts.nn_manager.nn_manager_GAN as nii_nn_wrapper_GAN
import core_scripts.startup_config as nii_startup


__author__ = "Xin Wang"
__email__ = "wangxin@nii.ac.jp"
__copyright__ = "Copyright 2021, Xin Wang"


def main():
    """ main(): the default wrapper for training and inference process
    Please prepare config.py and model.py
    """
    # arguments initialization
    args = nii_arg_parse.f_args_parsed()

    #                                                            
    nii_warn.f_print_w_date("Start program", level='h')
    nii_warn.f_print("Load module: %s" % (args.module_config))
    nii_warn.f_print("Load module: %s" % (args.module_model))
    prj_conf = importlib.import_module(args.module_config)
    prj_model = importlib.import_module(args.module_model)

    # initialization
    nii_startup.set_random_seed(args.seed)
    use_cuda = not args.no_cuda and torch.cuda.is_available()
    device = torch.device("cuda" if use_cuda else "cpu")

    # prepare data io    
    if True:
        # default, no truncating, no shuffling
        params = {'batch_size':  args.batch_size,
                  'shuffle': False,
                  'num_workers': args.num_workers}
                
        input_dim = sum(prj_conf.input_dims)
        output_dim = sum(prj_conf.output_dims)
        # initialize model
        model = prj_model.ModelGenerator(input_dim, output_dim, args, prj_conf)

        if args.trained_model == "":
            print("Please provide ---trained-model")
            sys.exit(1)
        else:
            checkpoint = torch.load(args.trained_model)
            
        # do inference and output data
        nii_nn_wrapper.f_convert_epoch_to_trained(
            args, model, device, checkpoint)
    # done
    return

if __name__ == "__main__":
    main()

