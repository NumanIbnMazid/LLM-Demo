# Use the base image
FROM flink:1.17.1

# Set environment variables
ENV CONDA_INSTALLER_URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    MINICONDA_DIR=/opt/miniconda \
    CONDA=/opt/miniconda/bin/conda \
    PYTHON=/opt/miniconda/envs/env/bin/python

# Update and install dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    cmake \
    wget \
    git \
    binutils \
    xz-utils \
    ca-certificates \
    gnupg2 \
    software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add the CUDA repository and install CUDA
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-4

# Set environment variables for CUDA
ENV PATH="/usr/local/cuda-12.4/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.4/lib64:${LD_LIBRARY_PATH}"
 
# environment variables 
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_REQUIRE_CUDA "cuda>=12.4"

# Download and install Miniconda
RUN wget $CONDA_INSTALLER_URL -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p $MINICONDA_DIR && \
    rm miniconda.sh

# Create a new environment named 'env'
RUN $CONDA create -y -n env python=3.10 && \
    $CONDA clean -afy

# Ensure conda is on PATH
ENV PATH="$MINICONDA_DIR/bin:$PATH"

# Activate the 'env' environment
SHELL ["conda", "run", "-n", "env", "/bin/bash", "-c"]

# Upgrade pip
RUN pip install --upgrade pip

# Install Python requirements
# RUN pip install Cython==3.0.10 setuptools==69.5.1 wheel==0.43.0

# Install llama.cpp with cuBLAS backend
RUN CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_CU4DA=on -DLLAMA_BLAS_VENDOR=OpenBLAS" FORCE_CMAKE=1 pip install llama-cpp-python==0.2.75

# Install langchain
RUN pip install langchain==0.2.0 langchain-community==0.2.0

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
