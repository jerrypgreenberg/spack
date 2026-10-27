#!/usr/bin/env bash

#SBATCH --job-name=petsc@3.24.4
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

declare -xr SPACK_PACKAGE='petsc@3.24.4'
declare -xr SPACK_COMPILER='gcc@13.3.0'
declare -xr SPACK_VARIANTS='~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii +fftw ~giflib +hdf5 ~hpddm ~hwloc +hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr +mpi +mumps ~p4est ~parmmg +ptscotch ~random123 ~rocm ~saws +scalapack +shared ~strumpack ~suite-sparse +superlu-dist ~tetgen ~trilinos ~valgrind'
declare -xr SPACK_DEPENDENCIES="^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ^intel-oneapi-mpi@2021.10.0) ^hdf5@1.14.3/$(spack find --format '{hash:7}' hdf5@1.14.3 % ${SPACK_COMPILER} +mpi ^intel-oneapi-mpi@2021.10.0) ^hypre@2.29.0/$(spack find --format '{hash:7}' hypre@2.29.0 % ${SPACK_COMPILER} ~int64 +mpi ^intel-oneapi-mpi@2021.10.0) ^mumps@5.5.1 % ${SPACK_COMPILER}  ^superlu-dist@8.1.2/$(spack find --format '{hash:7}' superlu-dist@8.1.2 % ${SPACK_COMPILER} ~int64 ^intel-oneapi-mpi@2021.10.0)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types petsc@3.24.4 % gcc@13.3.0 ~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii +fftw ~giflib +hdf5 ~hpddm ~hwloc +hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr +mpi +mumps ~p4est ~parmmg +ptscotch ~random123 ~rocm ~saws +scalapack +shared ~strumpack ~suite-sparse +superlu-dist ~tetgen ~trilinos ~valgrind "^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ~openmp ^intel-oneapi-mpi@2021.10.0) ^hdf5@1.14.3/$(spack find --format '{hash:7}' hdf5@1.14.3 % ${SPACK_COMPILER} +mpi ^intel-oneapi-mpi@2021.10.0) ^hypre@2.29.0/$(spack find --format '{hash:7}' hypre@2.29.0 % ${SPACK_COMPILER} ~int64 +mpi ^intel-oneapi-mpi@2021.10.0) ^mumps@5.5.1 % ${SPACK_COMPILER} ^superlu-dist@8.1.2/$(spack find --format '{hash:7}' superlu-dist@8.1.2 % ${SPACK_COMPILER} ~int64 ^intel-oneapi-mpi@2021.10.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi

time -p spack install --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all petsc@3.24.4 % gcc@13.3.0 ~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii +fftw ~giflib +hdf5 ~hpddm ~hwloc +hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr +mpi +mumps ~p4est ~parmmg +ptscotch ~random123 ~rocm ~saws +scalapack +shared ~strumpack ~suite-sparse +superlu-dist ~tetgen ~trilinos ~valgrind "^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} +mpi ~openmp ^intel-oneapi-mpi@2021.10.0) ^hdf5@1.14.3/$(spack find --format '{hash:7}' hdf5@1.14.3 % ${SPACK_COMPILER} +mpi ^intel-oneapi-mpi@2021.10.0) ^hypre@2.29.0/$(spack find --format '{hash:7}' hypre@2.29.0 % ${SPACK_COMPILER} ~int64 +mpi ^intel-oneapi-mpi@2021.10.0) ^mumps@5.5.1 % ${SPACK_COMPILER} ^superlu-dist@8.1.2/$(spack find --format '{hash:7}' superlu-dist@8.1.2 % ${SPACK_COMPILER} ~int64 ^intel-oneapi-mpi@2021.10.0)"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'py-petsc4py@3.24.4.sh'

sleep 20
