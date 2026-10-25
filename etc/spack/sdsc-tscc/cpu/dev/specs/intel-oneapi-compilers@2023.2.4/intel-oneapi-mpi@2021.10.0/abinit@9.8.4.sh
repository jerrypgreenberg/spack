#!/usr/bin/env bash

#SBATCH --job-name=abinit@9.8.4
#SBATCH --account=use300
#SBATCH --reservation=spack
#SBATCH --qos hotel
#SBATCH --partition=hotel
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=01:00:00
#SBATCH --output=%x.o%j.%N

declare -xr LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir UNIX_TIME="$(date +'%s')"

declare -xr SYSTEM_NAME='tscc'

declare -xr SPACK_VERSION='0.21.2'
declare -xr SPACK_INSTANCE_NAME='cpu'
declare -xr SPACK_INSTANCE_DIR=/cm/shared/apps/spack/0.21.2/cpu

declare -xr SLURM_JOB_SCRIPT="$(scontrol show job ${SLURM_JOB_ID} | awk -F= '/Command=/{print $2}')"
declare -xr SLURM_JOB_MD5SUM="$(md5sum ${SLURM_JOB_SCRIPT})"

declare -xr SCHEDULER_MODULE='slurm'

echo "${UNIX_TIME} ${SLURM_JOB_ID} ${SLURM_JOB_MD5SUM} ${SLURM_JOB_DEPENDENCY}" 
echo ""

cat "${SLURM_JOB_SCRIPT}"

. "${SPACK_INSTANCE_DIR}/share/spack/setup-env.sh"

# QE v6.7 does not concretize with a +scalapack dependency using 
# standard package available in spack v0.17.2? Fixed when updating to
# latest spack develop branch on 2022/03/11. Placed in sdsc spack 
# package repo. Then upgraded to QE v7.0 instead.

declare -xr SPACK_PACKAGE='abinit@9.8.4'
declare -xr SPACK_COMPILER='oneapi@2023.2.4'
declare -xr SPACK_VARIANTS='~openmp +scalapack +wannier90'
#declare -xr SPACK_DEPENDENCIES="^hdf5 +mpi +fortran +hl ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi +openmp) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^netlib-scalapack@2.2.0/$(spack find --format '{hash:7}' netlib-scalapack@2.2.0 % ${SPACK_COMPILER} ^intel-oneapi-mpi@2021.10.0 ^openblas@0.3.24 threads=none)"
declare -xr SPACK_DEPENDENCIES="^hdf5 +mpi +fortran +hl ^fftw@3.3.10/$(spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi ~openmp) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^netlib-scalapack@2.2.0/$(spack find --format '{hash:7}' netlib-scalapack@2.2.0 % ${SPACK_COMPILER} ^intel-oneapi-mpi@2021.10.0 ^openblas@0.3.24 threads=none)"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

module purge
module load "${SCHEDULER_MODULE}"
module load "${SPACK_INSTANCE_NAME}"
module load ${SPACK_COMPILER}
module list

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

export TMPDIR=/tmp
export SPACK_ENV_CC=mpiicc
export SPACK_ENV_CXX=mpiicpc
export SPACK_ENV_FC=mpiifort
fftw_hash=`spack find --format '{hash:7}' fftw@3.3.10 % ${SPACK_COMPILER} ~mpi +openmp`
hdf5_hash=`spack find --format '{hash:7}'  hdf5@1.8.23  % ${SPACK_COMPILER} +mpi +fortran +hl`
#FFTW3_LIBS="-L$(spack location -i /$fftw_hash )/lib -lfftw3_omp -lfftw3 -lfftw3f" \
#FFTW3_CPPFLAGS="-I$(spack location -i /$fftw_hash )/include" \
HDF5_LIBS="-L$(spack location -i /$hdf5_hash )/lib -lhdf5_fortran -lhdf5 -lz -lm -ldl" \
HDF5_FCFLAGS="-I$(spack location -i /$hdf5_hash)/include" \
HDF5_CPPFLAGS="-I$(spack location -i /$hdf5_hash)/include" \
time -p spack install --dirty --reuse --keep-stage -v --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all "${SPACK_SPEC}" 
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

#sbatch --dependency="afterok:${SLURM_JOB_ID}" 'vasp@6.4.3.sh'

sleep 20


