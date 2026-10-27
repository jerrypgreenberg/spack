sed -i s/gcc@10.2.0/gcc@8.5.0/g $1
#SBATCH --reservation=spack_dev_gpu
#SBATCH --gpus=1
