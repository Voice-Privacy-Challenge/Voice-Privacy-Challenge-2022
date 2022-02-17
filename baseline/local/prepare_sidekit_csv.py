from argparse import ArgumentParser
import subprocess
import io
import os
import shutil

def main():
    parser = ArgumentParser("Convert kaldi directory to sidekit csv")
    parser.add_argument("--wav-scp", type=str, required=True)
    parser.add_argument("--out-dir", type=str, required=True)
    args = parser.parse_args()
    wav_scp = args.wav_scp
    out_dir = args.out_dir
    if not os.path.exists(os.path.join(out_dir, "data")):
        os.mkdir(os.path.join(out_dir, "data"))
    out_wav_scp = open(os.path.join(out_dir, "wav.scp"), "w")
    for line in open(wav_scp):
        utt = line.split()[0]
        line = " ".join(line.split()[1:])
        # Detect which is file type. Only flac and wav supported
        if ".flac" in line:
            out_format = "flac"
        elif ".wav" in line:
            out_format = "wav"
        else:
            raise ValueError("Audio file type not supported")

        devnull = open(os.devnull, "w")
        try:
            wav_read_process = subprocess.Popen(
                line.strip()[:-1], stdout=subprocess.PIPE, shell=True, stderr=devnull
            )
            processed_wav_file = io.BytesIO(wav_read_process.communicate()[0])
            out_file_path = os.path.join(out_dir, "data", utt + '.' + out_format)
            with open(out_file_path, 'wb') as out_audio:
                shutil.copyfileobj(processed_wav_file, out_audio)
            out_wav_scp.write(utt + " " + os.path.join(out_file_path) + "\n")
        except Exception as e:
            raise IOError("Error processing file: {}\n{}".format(line, e))

if __name__ == "__main__":
    main()
