# Use the base image
FROM flink:1.17.1

# Update and install dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libffi-dev ffmpeg liblzma-dev lzma libgl1 gcc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CONDA_INSTALLER_URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    MINICONDA_DIR=/opt/miniconda \
    CONDA=/opt/miniconda/bin/conda \
    PYTHON=/opt/miniconda/envs/env/bin/python
 
# environment variables 
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_REQUIRE_CUDA "cuda>=12.2"

# Download and install Miniconda
RUN wget $CONDA_INSTALLER_URL -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p $MINICONDA_DIR && \
    rm miniconda.sh

# Create a new environment named 'env'
COPY environment.yml .
RUN $CONDA env create -f environment.yml && \
    $CONDA clean -afy

# Ensure conda is on PATH
ENV PATH="$MINICONDA_DIR/bin:$PATH"

# Activate the 'env' environment
SHELL ["conda", "run", "-n", "env", "/bin/bash", "-c"]

# Upgrade pip
RUN pip install --upgrade pip

# Install llama.cpp
RUN CMAKE_ARGS="-DLLAMA_CUDA=on" FORCE_CMAKE=1 pip install --upgrade --force-reinstall llama-cpp-python --no-cache-dir \
  --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu122

# Install langchain
COPY requirements.txt /requirements/requirements.txt
RUN pip3 install -r /requirements/requirements.txt

# Copy project files
COPY . /project

# Set PYTHONPATH
ENV PYTHONPATH="/project:${PYTHONPATH}"

# Set library path for Miniconda environment
ENV LD_LIBRARY_PATH="/opt/miniconda/envs/env/lib:${LD_LIBRARY_PATH}"

# Copy the entrypoint
COPY entrypoint.sh /entrypoint.sh

# Set executable permissions for the entrypoint script
RUN chmod +x /entrypoint.sh 
