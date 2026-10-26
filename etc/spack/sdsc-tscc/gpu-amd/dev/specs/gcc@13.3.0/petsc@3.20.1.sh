#!/usr/bin/env bash

#SBATCH --job-name=petsc@3.20.1
#SBATCH --account=use300
#SBATCH --reservation=spack_dev_gpu_4amd
#SBATCH --gpus=1
#SBATCH --partition=rtx3090
#SBATCH --qos condo-gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=48:00:00
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

# hash("python","uasyy5n4yauliglzcgk27zmfa3ltehdy")
#  imposed_constraint("2c5fvipdd5evacdfivwheqdtijr5om5z","node_compiler_version","zlib","gcc","10.2.0")
#  imposed_constraint("uasyy5n4yauliglzcgk27zmfa3ltehdy","hash","sqlite","uqy7ybgbejjeoveblo63sthenerqjmar")
#  imposed_constraint("uqy7ybgbejjeoveblo63sthenerqjmar","depends_on","sqlite","zlib","link")
#  imposed_constraint("uqy7ybgbejjeoveblo63sthenerqjmar","hash","zlib","2c5fvipdd5evacdfivwheqdtijr5om5z")
#  imposed_constraint("uqy7ybgbejjeoveblo63sthenerqjmar","node","sqlite")
#  node_compiler_version_set("zlib","gcc","8.5.0")

# condition(3855)
#  hash("python","uasyy5n4yauliglzcgk27zmfa3ltehdy")
#  imposed_constraint("5jrknc3vlekiult4nuhol72zpiakyb7d","node","ncurses")
#  imposed_constraint("uasyy5n4yauliglzcgk27zmfa3ltehdy","hash","sqlite","uqy7ybgbejjeoveblo63sthenerqjmar")
#  imposed_constraint("uqy7ybgbejjeoveblo63sthenerqjmar","hash","ncurses","5jrknc3vlekiult4nuhol72zpiakyb7d")
#  variant_condition(3855,"ncurses","abi")
#  variant_set("ncurses","abi","5")

# hash("python","vii2oxmukcdnaprxxdlsaydq7tjegc3j")
#  imposed_constraint("5xho2djgxmtrybtbc7q5q2yi5juesbqu","node","xz")
#  imposed_constraint("5xho2djgxmtrybtbc7q5q2yi5juesbqu","node_compiler_version","xz","gcc","10.2.0")
#  imposed_constraint("vii2oxmukcdnaprxxdlsaydq7tjegc3j","hash","xz","5xho2djgxmtrybtbc7q5q2yi5juesbqu")
#  node_compiler_version_set("xz","gcc","8.5.0")

declare -xr SPACK_PACKAGE='petsc@3.20.1'
declare -xr SPACK_COMPILER='gcc@13.3.0'
declare -xr SPACK_VARIANTS='~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii ~fftw ~giflib ~hdf5 ~hpddm ~hwloc ~hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr ~mpi ~mumps ~openmp ~p4est ~parmmg ~ptscotch ~random123 ~rocm ~saws ~scalapack +shared ~strumpack ~suite-sparse ~superlu-dist ~tetgen ~trilinos ~valgrind'
declare -xr SPACK_DEPENDENCIES="^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER}) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER})"
declare -xr SPACK_SPEC="${SPACK_PACKAGE} % ${SPACK_COMPILER} ${SPACK_VARIANTS} ${SPACK_DEPENDENCIES}"

printenv

spack config get compilers  
spack config get config  
spack config get mirrors
spack config get modules
spack config get packages
spack config get repos
spack config get upstreams

spack spec --long --namespaces --types petsc@3.20.1 % gcc@13.3.0 ~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii ~fftw ~giflib ~hdf5 ~hpddm ~hwloc ~hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr ~mpi ~mumps ~openmp ~p4est ~parmmg ~ptscotch ~random123 ~rocm ~saws ~scalapack +shared ~strumpack ~suite-sparse ~superlu-dist ~tetgen ~trilinos ~valgrind "^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER}) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack concretization failed.'
  exit 1
fi


export TMPDIR=/tmp
#time -p spack install --keep-stage -v --jobs "${SLURM_CPUS_PER_TASK}" --fail-fast --yes-to-all petsc@3.20.1 % gcc@13.3.0 ~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii ~fftw ~giflib ~hdf5 ~hpddm ~hwloc ~hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr ~mpi ~mumps ~openmp ~p4est ~parmmg ~ptscotch ~random123 ~rocm ~saws ~scalapack +shared ~strumpack ~suite-sparse ~superlu-dist ~tetgen ~trilinos ~valgrind "^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER}) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER})"
time -p spack install --keep-stage -v --jobs 1  --fail-fast --yes-to-all petsc@3.20.1 % gcc@13.3.0 ~X ~batch ~cgns ~complex +cuda cuda_arch=60,70,75,80,86 ~debug +double ~exodusii ~fftw ~giflib ~hdf5 ~hpddm ~hwloc ~hypre ~int64 ~jpeg ~knl ~libpng ~libyaml ~memkind +metis ~mkl-pardiso ~mmg ~moab ~mpfr ~mpi ~mumps ~openmp ~p4est ~parmmg ~ptscotch ~random123 ~rocm ~saws ~scalapack +shared ~strumpack ~suite-sparse ~superlu-dist ~tetgen ~trilinos ~valgrind "^cuda@12.6.3/$(spack find --format '{hash:7}' cuda@12.6.3 % ${SPACK_COMPILER}) ^python@3.11.6/$(spack find --format '{hash:7}' python@3.11.6 % ${SPACK_COMPILER}) ^openblas@0.3.24/$(spack find --format '{hash:7}' openblas@0.3.24 % ${SPACK_COMPILER} ~ilp64 threads=none) ^metis@5.1.0/$(spack find --format '{hash:7}' metis@5.1.0 % ${SPACK_COMPILER})"
if [[ "${?}" -ne 0 ]]; then
  echo 'ERROR: spack install failed.'
  exit 1
fi

spack module lmod refresh --delete-tree -y

sbatch --dependency="afterok:${SLURM_JOB_ID}" 'slepc@3.20.0.sh'

sleep 20
