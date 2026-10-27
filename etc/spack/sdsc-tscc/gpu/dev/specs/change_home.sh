files=`ls *.sh`
for file in $files;do
sed -i s/\\/home\\/jpg/\$\(HOME\)/ $file
done
#SBATCH --reservation=spack_dev_gpu
#SBATCH --gpus=1
