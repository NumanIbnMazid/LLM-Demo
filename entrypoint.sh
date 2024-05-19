#!/bin/bash

# Activate Conda environment
conda init bash
source ~/.bashrc
conda activate env

# pip freeze
python llama_cpp_main.py
