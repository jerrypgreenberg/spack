

# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
# ----------------------------------------------------------------------------

from spack import *
import os
import subprocess
import shutil
import glob
import urllib.parse


class Amber(Package,CudaPackage):
    """Amber is a suite of biomolecular simulation programs.

       Note: A manual download is required for Amber.
       Spack will search your current directory for the download file.
       Alternatively, add this file to a mirror so that Spack can find it.
       For instructions on how to set up a mirror, see
       http://spack.readthedocs.io/en/latest/mirrors.html"""

    version('24', sha256='d9c3667e9903941d4bfe2f57cfce40b108aca8f252228234a2bded1ae127d68a')

    homepage = "http://ambermd.org/"


    variant('mpi', description='Build MPI executables',
            default=True)
    variant('cuda', description='Build cuda execuatables',
            default=False)
    depends_on('zlib')
    depends_on('flex', type='build')
    depends_on('bison', type='build')
    depends_on('netcdf-c')
    depends_on('netcdf-fortran')
    depends_on('mpi', when='+mpi')
    depends_on('cuda', when='+cuda')
    depends_on('cmake')
    depends_on('zlib')
    depends_on('bzip2')
 
    def url_for_version(self, version):
            return "file://{0}/pmemd"+str(version)+".tar.bz2".format(os.getcwd())

    def install(self, spec, prefix):
        compiler=spec.compiler.name
        if compiler == "gcc":
            ambercompiler = "GNU"
        elif compiler == "intel":
            ambercompiler = "INTEL"
        elif compiler == "pgi":
            ambercompiler = "PGI"
 
        args = []
        args.append(os.getcwd());
        args.append('-DCMAKE_INSTALL_PREFIX='+prefix)
        args.append('-DCOMPILER='+ambercompiler)
        args.append('-DMPI=FALSE')
        args.append('-DCUDA=FALSE')
        args.append('-DINSTALL_TESTS=TRUE')
        args.append('-DDOWNLOAD_MINICONDA=FALSE')
        args.append('-DBUILD_PYTHON=FALSE')
        args.append('-DNetCDF_INCLUDES='+join_path(spec['parallel-netcdf'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_F90='+join_path(spec['netcdf-fortran'].prefix,'lib','libnetcdff.so'))
        args.append('-DNetCDF_INCLUDES_F90='+join_path(spec['netcdf-fortran'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec['netcdf-c'].prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec['netcdf-c'].prefix,'include'))
        args.append('-DNetCDF_LIBRARIES_C='+join_path(spec['netcdf-c'].prefix,'lib','libnetcdf.so'))
        args.append('-DNetCDF_INCLUDE_C='+join_path(spec['netcdf-c'].prefix,'include'))
        args.append('-DBUILD_PERL=FALSE')
        args.append('-DBUILD_GUI=FALSE')
        args.append('-DPMEMD_ONLY=TRUE')
        args.append('-DCHECK_UPDATES=FALSE')

        os.chdir('build')
        if not '+cuda' in spec:
            cmake(*args)
            make('install')
            if '+mpi' in spec:
                for x,y in enumerate(args):
                    if 'DMPI' in y:
                        args.remove(y)
                        args.insert(x,'-DMPI=TRUE')
                cmake(*args)
                make('install')
        else:
            for x,y in enumerate(args):
                for x,y in enumerate(args):
                    if 'DCUDA' in y:
                        args.remove(y)
                        args.insert(x,'-DCUDA=TRUE')
                cmake(*args)
                make('install')
                if '+mpi' in spec:
                    for x,y in enumerate(args):
                        if 'DMPI' in y:
                            args.remove(y)
                            args.insert(x,'-DMPI=TRUE')
                cmake(*args)
                make('install')
        subprocess.run(['sh',join_path(os.path.dirname(self.module.__file__),'Miniforge3-Linux-x86_64.sh'),'-b','-p',join_path(prefix,'ambertools25')])
        subprocess.run(['conda','create','-y','--name','AmberTools25','python=3.12'])
        subprocess.run(['conda','activate','AmberTools25'])
        subprocess.run(['conda','config','--add','channels','conda-forge'])
        subprocess.run(['conda','config','--set','channel_priority','strict'])
        subprocess.run(['conda','install','-y','dacase::ambertools-dac=25'])

    def setup_build_environment(self, env):
        env.prepend_path('PATH',join_path(prefix,'ambertools25','bin'))
        env.set('CONDA_PYTHON_EXE',join_path(prefix,'ambertools25','bin','python'))
        env.set('CONDA_EXE',join_path(prefix,'ambertools25','bin','conda'))
        env.set('CONDA_PREFIX',join_path(prefix,'ambertools25'))
        env.set('CONDA_DEFAULT_ENV','base')
        env.set('CONDA_SHLVL','1')

    def setup_run_environment(self, env):
        env.prepend_path('PATH',join_path(prefix,'ambertools25','bin'))
        env.set('CONDA_PYTHON_EXE',join_path(prefix,'ambertools25','bin','python'))
        env.set('CONDA_EXE',join_path(prefix,'ambertools25','bin','conda'))
        env.set('CONDA_PREFIX',join_path(prefix,'ambertools25'))
        env.set('CONDA_DEFAULT_ENV','base')
        env.set('CONDA_SHLVL','1')
