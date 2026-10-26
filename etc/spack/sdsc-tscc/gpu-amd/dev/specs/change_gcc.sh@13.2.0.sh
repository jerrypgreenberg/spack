sed -i s/gcc@8.5.0/gcc@11.5.0/g $file
#SBATCH --reservation=spack_dev_gpu_4amd
#SBATCH --gpus=1
