ARG python_version=3.6
ARG cuda_version=9.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

# Local user
ENV NB_USER monad
ENV NB_UID 1000
ENV NB_DIR /src

# Miniconda
ENV CONDA Miniconda3-4.4.10-Linux-x86_64.sh
ENV SHA256 0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV PYTHONPATH='$NB_DIR/:$PYTHONPATH'

# Notebook
ENV NB_PORT 8888

# Add installs
ADD conda.txt /tmp/conda.txt
ADD pip.txt /tmp/pip.txt
ADD apt.txt /tmp/apt.txt

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat /tmp/apt.txt) && \
    rm -rf /var/lib/apt/lists/*

# Install conda
RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/$CONDA && \
    echo "$SHA256 *$CONDA" | sha256sum -c - && \
    /bin/bash /$CONDA -f -b -p $CONDA_DIR && \
    rm $CONDA && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

# Add local user
RUN useradd -m -s /bin/zsh -N -u $NB_UID $NB_USER && \
    chown $NB_USER $CONDA_DIR -R && \
    mkdir -p $NB_DIR && \
    chown $NB_USER $NB_DIR

# Change user
USER $NB_USER

# Update conda and pip
RUN conda update -n base conda && \
    conda install -y python=${python_version} && \
    pip install --upgrade pip

# Install conda and pip packages
RUN conda install --yes --file /tmp/conda.txt
RUN pip --no-cache-dir install -r /tmp/pip.txt

# Remove conda cache
RUN conda clean -yt

# Remove install files
RUN rm -rf /tmp/*

# Add theano configs
ADD theanorc /home/$NB_USER/.theanorc

# Change working direcoty
WORKDIR $NB_DIR
EXPOSE $NB_PORT

CMD jupyter notebook --port=$NB_PORT --ip=0.0.0.0
