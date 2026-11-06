# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import subprocess


class Nbo(MakefilePackage):
    """The Natural Bond Orbital (NBO) program NBO 7.0 is a discovery tool for chemical insights from complex wavefunctions."""

    homepage = "https://nbo6.chem.wisc.edu/"
#   url      = "file:////home/mahidhar/Downloads/nbo7.0-src.tar"
    url      = "file:///tscc/nfs/home/spack_dev_cpu/nbo/nbo7.0-src.tar"

    version('7.0', sha256='fcb2d811bb0124f827bdcc2ab301b56b09b832cbf5ac3b09764b60b0767f81b2')

    depends_on('blas')
    depends_on('lapack')

    variant('blas', default=True, description='Enables BLAS library')
    variant('lapack', default=True, description='Enables LAPACK library')
    variant('int4', default=False, description='8 bit integers by default')


    def edit(self, spec, prefix):
        filter_file('CC = gcc',"CC = {0}".format(spack_cc),'Make.config')
        filter_file('FC = gfortran',"FC = {0}".format(spack_fc),'Make.config')
        filter_file('NBOBIN ../../bin',"NBOBIN {0}".format(prefix.bin),join_path('tests','gennbo','gennbo'))
        if 'gfortran' in spack_fc:
            filter_file('FC_VERSION = 5.5',"FC_VERSION = {0}".format(self.compiler.version),'Make.config')
        filter_file('NBODIR = ~/nbo7',"NBODIR = {0}".format(self.stage.source_path),'Make.config')
        filter_file('BINDIR ~/nbo7/bin',"BINDIR {0}".format(prefix.bin),join_path('bin','gaunbo6'))
        filter_file('BINDIR ~/nbo7/bin',"BINDIR {0}".format(prefix.bin),join_path('bin','gaunbo7'))
        if '+int4' in spec:
            filter_file('INT = i8','INT = i4','Make.config')
            filter_file('setenv INT i8','setenv INT i4','gennbo')
            filter_file('export INT=i8','export INT=i4',join_path('tests','gennbo.sh'))
            filter_file('setenv INT i8','setenv INT i4',join_path('tests','gennbo','gennbo'))
            filter_file('setenv INT i8','setenv INT i4',join_path('bin','gaunbo6'))
            filter_file('setenv INT i8','setenv INT i4',join_path('bin','gaunbo7'))
        if '+blas' in spec:
            filter_file('BLAS = false','BLAS = true','Make.config')
            filter_file('BLASLIB = -L/usr/lib/x86_64-linux-gnu -lblas',"BLASLIB = {0}".format(spec['blas'].libs),'Make.config')

        if '+lapack' in spec:
            filter_file('LAPACK = false','LAPACK = true','Make.config')
            filter_file('LAPACKLIB = -L/usr/lib/x86_64-linux-gnu -llapack',"LAPACKLIB = {0}".format(spec['lapack'].libs),'Make.config')

    def install(self, spec, prefix):
        install_tree('bin',join_path(prefix,'bin'))
        install_tree('tests',join_path(prefix,'tests'))
        install('tests/gennbo/gennbo', prefix.bin)

    @run_after('install')
    @on_package_attributes(run_tests=True)

    def test(self):
        with working_dir(join_path(self.prefix,'tests','gennbo')):
            subprocess.run([join_path(prefix.bin,'gennbo'),'a.3'])
            subprocess.run(['sleep', '10'])
            output=subprocess.run(['cat','a.3.nbo'],stdout=subprocess.PIPE)
            output=output.stdout.decode("utf-8")
            teststring='Total Lewis   17.95205  ( 99.7336%)'
            if teststring in output:
                print('PASSED')
            else:
                print('FAILED')
