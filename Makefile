help:
	@cat Makefile

GPU?=0,1
DOCKER_FILE=Dockerfile
DOCKER=GPU=$(GPU) nvidia-docker
BACKEND=tensorflow

NAME=$(shell dirname `pwd` | xargs basename)
SRC?=$(shell dirname `pwd`)

DATA?="/mnt/hermes/data"
NB_DIR?=$(shell sed -n 's/^ENV NB_DIR *//p' $(DOCKER_FILE))
PYTHON_VERSION?=$(shell sed -n 's/^ARG python_version=*//p' $(DOCKER_FILE))
CUDA_VERSION?=$(shell sed -n 's/^ARG cuda_version=*//p' $(DOCKER_FILE))
CUDNN_VERSION?=$(shell sed -n 's/^ARG cudnn_version=*//p' $(DOCKER_FILE))

build:
	docker build -t $(NAME) --build-arg python_version=$(PYTHON_VERSION) --build-arg cuda_version=$(CUDA_VERSION) --build-arg cudnn_version=$(CUDNN_VERSION) -f $(DOCKER_FILE) .

bash: build
	$(DOCKER) run -it -v $(SRC):$(NB_DIR)/easy -v $(DATA):$(NB_DIR)/data --env KERAS_BACKEND=$(BACKEND) $(NAME) bash

ipython: build
	$(DOCKER) run -it -v $(SRC):$(NB_DIR)/easy -v $(DATA):$(NB_DIR)/data --env KERAS_BACKEND=$(BACKEND) $(NAME) ipython

lab: build
	$(DOCKER) run -it -v $(SRC):$(NB_DIR)/easy -v $(DATA):$(NB_DIR)/data --net=host --env KERAS_BACKEND=$(BACKEND) $(NAME)

test: build
	$(DOCKER) run -it -v $(SRC):$(NB_DIR)/easy -v $(DATA):$(NB_DIR)/data --env KERAS_BACKEND=$(BACKEND) $(NAME) py.test $(TEST)

