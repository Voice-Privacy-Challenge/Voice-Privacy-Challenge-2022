#!/bin/bash


# Install expect for downloading files using sftp
# sudo apt install expect


PASSWD="getdata" # Enter your sftp password here
expect -c 'spawn sftp getdata@voiceprivacychallenge.univ-avignon.fr; 

expect "*password: ";
send "$env(PASSWD)\r";
expect "sftp>";
send "cd /challengedata \r";
expect "sftp>";
send "get models.tar.gz \r";
expect "sftp>";
send "bye \r"'

# Extract all pretrained models
tar -zxvf models.tar.gz

popd >&/dev/null











