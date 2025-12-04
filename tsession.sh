#!/bin/bash

dir_name=$(basename $PWD)

tmux new-session -s $dir_name -n TODO
tmux new-window -t $dir_name -n CODE
