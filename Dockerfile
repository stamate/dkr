ARG python_version=3.6
ARG cuda_version=9.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

# Local user
ENV NB_USER monad
ENV NB_UID 1000
ENV NB_DIR /src

# Miniconda
ENV CONDA Miniconda3-4.3.31-Linux-x86_64.sh
ENV CONDA_MD5 7fe70b214bee1143e3e3f0467b71453c
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV PYTHONPATH='$NB_DIR/:$PYTHONPATH'

# Notebook
ENV NB_PORT 8888

# Add installs
ADD conda.txt /tmp/conda.txt
ADD pip.txt /tmp/pip.txt
ADD apt.txt /tmp/apt.txt
ADD lab.txt /tmp/lab.txt

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat /tmp/apt.txt) && \
    rm -rf /var/lib/apt/lists/*

# Install conda
RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/$CONDA && \
    echo "$CONDA_MD5 *$CONDA" | md5sum -c - && \
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
RUN pip install --upgrade pip

# Install conda, pip and jupyterlab packages
RUN conda install --yes --file /tmp/conda.txt -c conda-forge
RUN pip --no-cache-dir install -r /tmp/pip.txt
#RUN cat /tmp/lab.txt | xargs jupyter labextension install

# Remove conda cache
RUN conda clean -yt

USER root
# Remove install files
RUN rm -rf /tmp/*

USER $NB_USER
# Add on-my-zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Change shell to zsh
ENV SHELL /bin/zsh

# Add theano configs
ADD theanorc /home/$NB_USER/.theanorc

# Change working direcoty
WORKDIR $NB_DIR
EXPOSE $NB_PORT

CMD jupyter lab --port=$NB_PORT --ip=0.0.0.0 --NotebookApp.password='sha1:b4e4e0deb244:a8b99d99395ec48ea1d22e0ed3f2773d268cf5c0'
