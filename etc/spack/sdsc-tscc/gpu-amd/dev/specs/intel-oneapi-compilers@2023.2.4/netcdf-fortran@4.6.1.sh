#!/usr/bin/env bash

#SBATCH --job-name=netcdf-fortran@4.6.1
#SBATCH --account=use300
#SBATCH --reservation=spack_dev_gpu_4amd
#SBATCH --gpus=1
##SBATCH --reservation=root_73
#SBATCH --partition=rtx3090
#SBATCH --qos condo-gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=00:30:00
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
declare -xr COMPILER_MODULE='intel-oneapi-compilers/2023.2.4'

module purge
module load "${SCHEDULER_MODULE}"
module load ${SPACK_INSTANCE_NAME}
module load ${COMPILER_MODULE}
module list
. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

declare -xr INTEL_LICENSE_FILE='40000@elprado.sdsc.edu:40200@elprado.sdsc.edu'
declare -xr SPACK_PACKAGE='netcdf-fortran@4.6.1'
declare -xr SPACK_COMPILER='oneapi@2023.2.4'
declare -xr SPACK_VARIANTS='~doc +pic +shared'
declare -xr SPACK_DEPENDENCIES="^netcdf-c@4.9.2/$(spack find --format '{hash:7}' netcdf-c@4.9.2 % ${SPACK_COMPILER} ~mpi)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

#spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'arpack-ng@3.9.0.sh'

sleep 20
