#!/bin/bash
shfiles=`cat $1`
file=$2
for shfile in $shfiles; do
  while read -r package_version;do
    newversion=`spack info $package_version |grep -A 1 Preferred |sed -n 2p |awk '{print $1}'`
    package_file=`echo $package_version |sed s/@.*//`
    package_file=${package_file}@${newversion}
    echo $package_version $package_file
    sed -i '' s/$package_version/$package_file/g $shfile
  done <$file
done
#SBATCH --reservation=spack
