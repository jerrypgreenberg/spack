#!/usr/bin/env bash

#SBATCH --job-name=vasp@6.6.0
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
declare -xr COMPILER_MODULE='nvhpc@23.9'
declare -xr COMPILER_LMOD_MODULE='nvhpc/23.9'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

module purge
module load "${SCHEDULER_MODULE}"
module load "${SPACK_INSTANCE_NAME}/${SPACK_VERSION}"
#module use "${SPACK_ROOT}/share/spack/lmod/linux-rocky8-x86_64/Core"
module load "${COMPILER_LMOD_MODULE}"

module list

declare -xr SPACK_PACKAGE='vasp@6.6.0'
declare -xr SPACK_COMPILER="nvhpc@23.9"
declare -xr SPACK_VARIANTS="+acc +openmp +scalapack ~vaspsol"
declare -xr SPACK_DEPENDENCIES="^intel-oneapi-mkl@2023.2.0 % ${SPACK_COMPILER} ^nvhpc+mpi"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types vasp@6.6.0 % nvhpc@23.9 +acc +openmp +scalapack ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

export TMPDIR=/tmp
time -p spack install --keep-stage -v --jobs 1 --fail-fast --yes-to-all vasp@6.6.0 % nvhpc@23.9  +acc  +openmp +scalapack  ~vaspsol "${SPACK_DEPENDENCIES}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" ''

sleep 20
