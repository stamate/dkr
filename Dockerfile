ARG cuda_version=9.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      bzip2 \
      g++ \
      git \
      graphviz \
      libgl1-mesa-glx \
      libhdf5-dev \
      openmpi-bin \
      wget && \
    rm -rf /var/lib/apt/lists/*

# Install conda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

ENV CONDA Miniconda3-4.4.10-Linux-x86_64.sh
ENV SHA256 0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891

RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/$CONDA && \
    echo "$SHA256 *$CONDA" | sha256sum -c - && \
    /bin/bash /$CONDA -f -b -p $CONDA_DIR && \
    rm $CONDA && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

# Install Python packages and keras
ENV NB_USER monad
ENV NB_UID 1000

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    chown $NB_USER $CONDA_DIR -R && \
    mkdir -p /src && \
    chown $NB_USER /src

USER monad

ARG python_version=3.6

RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install \
      sklearn_pandas \
      tensorflow-gpu && \
    pip install https://cntk.ai/PythonWheel/GPU/cntk-2.1-cp36-cp36m-linux_x86_64.whl && \
    conda install \
      bcolz \
      h5py \
      matplotlib \
      mkl \
      nose \
      notebook \
      Pillow \
      pandas \
      pygpu \
      pyyaml \
      scikit-learn \
      six \
      theano && \
    git clone git://github.com/keras-team/keras.git /src && pip install -e /src[tests] && \
    pip install git+git://github.com/keras-team/keras.git && \
    conda clean -yt

ADD theanorc /home/keras/.theanorc

ENV PYTHONPATH='/src/:$PYTHONPATH'

WORKDIR /src

EXPOSE 8888

CMD jupyter notebook --port=8888 --ip=0.0.0.0
