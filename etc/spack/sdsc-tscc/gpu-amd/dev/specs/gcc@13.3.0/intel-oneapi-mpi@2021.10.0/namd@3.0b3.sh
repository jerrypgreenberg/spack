#!/usr/bin/env bash

#SBATCH --job-name=namd@3.0b3
#SBATCH --account=use300
#SBATCH --reservation=spack_dev_gpu_4amd
#SBATCH --gpus=1
#SBATCH --partition=rtx3090
#SBATCH --qos condo-gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=02:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.21.2'
declare -xr SPACK_INSTANCE_NAME='gpu-amd'
declare -xr SPACK_INSTANCE_DIR=/cm/shared/apps/spack/0.21.2/gpu-amd

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

module purge
module load "${SCHEDULER_MODULE}"
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

# Selected arch file arch/linux-x86_64-spack.arch contains:
# 
# NAMD_ARCH = linux-x86_64
# CHARMARCH = mpi-linux-x86_64
# CXX = /home/mkandes/cm/shared/apps/spack/0.21.2/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-10.2.0-i62tgsoexc6ya4h7urwhriiujk22nrnj/bin/g++ -std=c++11
# CXXOPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
# CC = /home/mkandes/cm/shared/apps/spack/0.21.2/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-10.2.0-i62tgsoexc6ya4h7urwhriiujk22nrnj/bin/gcc
# COPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#
# ERROR: MPI-based Charm++ arch  is not compatible with CUDA NAMD.
# ERROR: Non-SMP Charm++ arch  is not compatible with CUDA NAMD.
# ERROR: CUDA builds require non-MPI SMP or multicore Charm++ arch for reasonable performance.
#
# Consider ucx-smp or verbs-smp (InfiniBand), gni-smp (Cray), or multicore (single node).

# Selected arch file arch/linux-x86_64-spack.arch contains:
#
# NAMD_ARCH = linux-x86_64
# CHARMARCH = ucx-linux-x86_64
# CXX = /home/mkandes/cm/shared/apps/spack/0.21.2/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-10.2.0-i62tgsoexc6ya4h7urwhriiujk22nrnj/bin/g++ -std=c++11
# CXXOPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
# CC = /home/mkandes/cm/shared/apps/spack/0.21.2/gpu/opt/spack/linux-rocky8-skylake_avx512/gcc-8.5.0/gcc-10.2.0-i62tgsoexc6ya4h7urwhriiujk22nrnj/bin/gcc
# COPTS = -m64 -O3 -fexpensive-optimizations                                         -ffast-math -lpthread -march=cascadelake -mtune=cascadelake
#
# ERROR: Non-SMP Charm++ arch  is not compatible with CUDA NAMD.
# ERROR: CUDA builds require non-MPI SMP or multicore Charm++ arch for reasonable performance.
#
# Consider ucx-smp or verbs-smp (InfiniBand), gni-smp (Cray), or multicore (single node). 

declare -xr SPACK_PACKAGE='namd@3.0b3'
declare -xr SPACK_COMPILER='gcc@13.3.0'
declare -xr SPACK_VARIANTS='+cuda cuda_arch=60,70,75,80,86 interface=tcl'
declare -xr SPACK_DEPENDENCIES="^charmpp@8.0.0/$(spack find --format '{hash:7}' charmpp@8.0.0 % ${SPACK_COMPILER}) ^intel-oneapi-mpi@2021.10.0 ^fftw@3.3.10 % ${SPACK_COMPILER} ^tcl@8.6.12/$(spack find --format '{hash:7}' tcl@8.6.12 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get package s
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types namd@3.0b3 % gcc@13.3.0 +cuda cuda_arch=60,70,75,80,86 interface=tcl "^charmpp@8.0.0/$(spack find --format '{hash:7}' charmpp@8.0.0 % ${SPACK_COMPILER}) ^intel-oneapi-mpi@2021.10.0 ^fftw@3.3.10 % ${SPACK_COMPILER} ^tcl@8.6.12/$(spack find --format '{hash:7}' tcl@8.6.12 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all namd@3.0b3 % gcc@13.3.0 +cuda cuda_arch=60,70,75,80,86 interface=tcl "^charmpp@8.0.0/$(spack find --format '{hash:7}' charmpp@8.0.0 % ${SPACK_COMPILER}) ^intel-oneapi-mpi@2021.10.0 ^fftw@3.3.10 % ${SPACK_COMPILER} ^tcl@8.6.12/$(spack find --format '{hash:7}' tcl@8.6.12 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'plumed@2.9.0.sh'

sleep 20
