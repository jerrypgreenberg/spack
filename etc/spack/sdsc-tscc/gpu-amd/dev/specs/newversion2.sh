#!/bin/bash
mkdir -p oldversions
file=$1
while read -r package_version;do
  newversion=`spack info $package_version |grep -A 1 Preferred |sed -n 2p |awk '{print $1}'`
# package_files=`find . -name \*${package_version}\*.sh | tr  '\n' ' '`
  package_files=`ls ${package_version}.sh`
  for package_file in $package_files; do
    echo $package_file
    dirname=`dirname $package_file`
    basename=`basename $package_file`
    oldversion=`echo $basename |sed 's/^.*@//'|sed 's/.sh//'`
    package=`echo $basename | sed 's/@.*//'`
    if [ $newversion != $oldversion ]; then
      cp $package_file $dirname/$package'@'${newversion}.sh
      sed -i "s/${package}@${oldversion}/${package}@${newversion}/g" $dirname/${package}'@'${newversion}.sh
      oldnextversion=`grep afterok $package_file | grep ^sbatch|awk '{print $3}' | sed "s/'//g"| sed "s/\.sh//"`
      nextpackage=`echo $oldnextversion | sed 's/@.*//'`
      newnextversion=`spack info $oldnextversion |grep -A 1 Preferred |sed -n 2p |awk '{print $1}'`
      sed -i "s/$oldnextversion/${nextpackage}@${newnextversion}/g" $dirname/${package}'@'${newversion}.sh
      mv $package_file oldversions
    fi
  done
done <$file
#SBATCH --reservation=spack_dev_gpu_4amd
#SBATCH --gpus=1
