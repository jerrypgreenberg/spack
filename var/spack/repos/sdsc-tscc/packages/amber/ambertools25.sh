#!/bin/bash -x
unset $(env | cut -d= -f1)
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:$PATH
export PATH=$1/ambertools25/bin:$PATH
export CONDA_PYTHON_EXE=$1/ambertools25/bin/python
export CONDA_EXE=$1/ambertools25/bin/conda
export CONDA_PREFIX=$1/ambertools25
export CONDA_DEFAULT_ENV=base
export CONDA_SHLVL=1
sh $2/Miniforge3-Linux-x86_64.sh -b -p $1/ambertools25
conda create -y --name AmberTools25 python=3.12
conda config --add channels conda-forge
conda config --set channel_priority strict
conda install -y dacase::ambertools-dac=25
