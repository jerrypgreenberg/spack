sed -i s/gcc@8.5.0/gcc@11.4.1/g $file
#SBATCH --reservation=spack_dev_gpu
#SBATCH --gpus=1
