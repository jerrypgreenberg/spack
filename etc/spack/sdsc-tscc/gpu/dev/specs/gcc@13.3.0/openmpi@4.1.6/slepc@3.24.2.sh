#!/usr/bin/env bash

#SBATCH --job-name=slepc@3.24.3
#SBATCH --account=use300
#SBATCH --reservation=spack_dev_gpu
#SBATCH --gpus=1
#SBATCH --partition=condo
#SBATCH --qos condo
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.21.2'
declare -xr SPACK_INSTANCE_NAME='gpu'
declare -xr SPACK_INSTANCE_DIR=/cm/shared/apps/spack/0.21.2/gpu

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

# Error: Package slepc does not depend on arpack-ng
declare -xr SPACK_PACKAGE='slepc@3.24.2'
declare -xr SPACK_COMPILER='gcc@13.3.0'
declare -xr SPACK_VARIANTS='~arpack ~blopex +cuda cuda_arch=60,70,75,80,86 ~rocm'
declare -xr SPACK_DEPENDENCIES="^petsc@3.24.4/$(spack find --format '{hash:7}' petsc@3.24.4% ${SPACK_COMPILER} ~complex +mpi ^openmpi@4.1.6) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER})  ^hypre@2.29.0/$(spack find --format '{hash:7}' hypre@2.29.0 % ${SPACK_COMPILER} ~int64 +mpi ^openmpi@4.1.6)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types slepc@3.24.2 % gcc@13.3.0 ~arpack ~blopex +cuda cuda_arch=60,70,75,80,86 ~rocm "^petsc@3.24.4/$(spack find --format '{hash:7}' petsc@3.24.4 % ${SPACK_COMPILER} ~complex +mpi ^openmpi@4.1.6) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^hypre@2.29.0/$(spack find --format '{hash:7}' hypre@2.29.0 % ${SPACK_COMPILER} ~int64 +mpi ^openmpi@4.1.6)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

export TMPDIR=/tmp
time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all slepc@3.24.2 % gcc@13.3.0 ~arpack ~blopex +cuda cuda_arch=60,70,75,80,86 ~rocm "^petsc@3.24.4/$(spack find --format '{hash:7}' petsc@3.24.4 % ${SPACK_COMPILER} ~complex +mpi ^openmpi@4.1.6) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'py-petsc4py@3.24.4.sh'

sleep 20
