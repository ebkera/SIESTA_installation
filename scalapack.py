#!/usr/bin/python

# -----------------------------------------
# ScaLAPACK installer
# University of Tennessee Knoxville
# October 16, 2007
# ----------------------------------------



from utils import writefile, runShellCommand, killfiles, downloader, getURLName
import sys
import os
import framework
import shutil


class Scalapack(framework.Framework):
    """ This class takes care of the ScaLAPACK installation. """

    def __init__(self, argv, config):
        framework.Framework.__init__(self, argv, config)
        
    def resume(self):
        print '\n','='*40
        print 'ScaLAPACK installer is starting now. Buckle up!'
        print '='*40

        self.down_install()

        framework.Framework.resume(self)


    def write_slmakeinc(self):
        """ Writes the SLmake.inc file for ScaLAPACK installation """

        sdir = os.getcwd()
        print 'Writing SLmake.inc...',
        sys.stdout.flush()
        writefile('SLmake.inc',"""
#
#  C preprocessor definitions:  set CDEFS to one of the following:
#
#     -DNoChange (fortran subprogram names are lower case without any suffix)
#     -DUpCase   (fortran subprogram names are upper case without any suffix)
#     -DAdd_     (fortran subprogram names are lower case with "_" appended)

CDEFS         = """+self.mangling+"""

#
#  The fortran and C compilers, loaders, and their flags
#

FC            = """+self.config.mpif90+""" -fallow-argument-mismatch
CC            = """+self.config.mpicc+"""
NOOPT         = """+self.config.noopt+"""
FCFLAGS       = """+self.config.fcflags+"""
CCFLAGS       = """+self.config.ccflags+"""
SRCFLAG       =
FCLOADER      = $(FC)
CCLOADER      = $(CC)
FCLOADFLAGS   = """+self.config.ldflags_fc+"""
CCLOADFLAGS   = """+self.config.ldflags_c+"""

#
#  The archiver and the flag(s) to use when building archive (library)
#  Also the ranlib routine.  If your system has no ranlib, set RANLIB = echo
#

ARCH          = ar
ARCHFLAGS     = cr
RANLIB        = """+self.config.ranlib+"""

#
#  The name of the ScaLAPACK library to be created
#

SCALAPACKLIB  = libscalapack.a

#
#  BLAS, LAPACK (and possibly other) libraries needed for linking test programs
#

BLASLIB       = """+self.config.blaslib+"""
LAPACKLIB     = """+self.config.lapacklib+"""
LIBS          = $(LAPACKLIB) $(BLASLIB)
        """)

        self.scalapackdir = sdir
        print 'done.'




    def down_install(self):
        """ Download ind install ScaLAPACK """

        savecwd = os.getcwd()

        # creating the build and lib dirs if don't exist
        if not os.path.isdir(os.path.join(self.prefix,'lib')):
	        os.mkdir(os.path.join(self.prefix,'lib'))

        if not os.path.isdir(os.path.join(self.prefix,'include')):
            os.mkdir(os.path.join(self.prefix,'include'))

        if not os.path.isdir(os.path.join(os.getcwd(),'log')):
            os.mkdir(os.path.join(os.getcwd(),'log'))

        if(not os.path.isfile(os.path.join(os.getcwd(),getURLName(self.scalapackurl)))):
            print "Downloading ScaLAPACK...",
            downloader(self.scalapackurl, self.downcmd)
            print "done"
        comm = 'gunzip -f scalapack.tgz'
        (output, error, retz) = runShellCommand(comm)
        if retz:
            print '\n\nScaLAPACK: cannot unzip scalapack.tgz'
            print 'error is:\n','*'*40,'\n',comm,'\n',error,'\n','*'*40
            sys.exit()
        

        comm = 'tar xf scalapack.tar'
        (output, error, retz) = runShellCommand(comm)
        if retz:
            print '\n\nScaLAPACK: cannot untar scalapack.tar'
            print 'error is:\n','*'*40,'\n',comm,'\n',error,'\n','*'*40
            sys.exit()
        os.remove('scalapack.tar')
        
        # change to ScaLAPACK dir
        # os.chdir(os.path.join(os.getcwd(),'scalapack-2.0.0'))
        comm = 'ls -1 | grep scalapack'
        (output, error, retz) = runShellCommand(comm)
        if retz:
		    print '\n\nScaLAPACK: error changing to ScaLAPACK dir'
		    print 'stderr:\n','*'*40,'\n','   ->  no ScaLAPACK directory found','\n','*'*40
		    sys.exit()
        rep_name = output.replace ("\n","")
        print 'Installing ',rep_name,'...'
        rep_name = os.path.join(os.getcwd(),rep_name)

        os.chdir(rep_name)

        self.write_slmakeinc()

        print 'Compiling BLACS, PBLAS and ScaLAPACK...',
        sys.stdout.flush()
        comm = self.make+" lib"
        (output, error, retz) = runShellCommand(comm)
        if retz:
            print '\n\nScaLAPACK: error building ScaLAPACK'
            print 'error is:\n','*'*40,'\n',comm,'\n',error,'\n','*'*40
            writefile(os.path.join(savecwd,'log/scalog'), output+error)
            sys.exit()

        fulllog = os.path.join(savecwd,'log/scalog')
        writefile(fulllog, output+error)
        print 'done'
        # move lib to the lib directory
        shutil.copy('libscalapack.a',os.path.join(self.prefix,'lib/libscalapack.a'))
        self.config.scalapacklib  = '-L'+os.path.join(self.prefix,'lib')+' -lscalapack'
        print "Getting ScaLAPACK version number...",
        # This function simply calls ScaLAPACK pilaver routine and then
        # checks if compilation, linking and execution are succesful

        sys.stdout.flush()
        writefile('tmpf.f',"""

      PROGRAM ScaLAPACK_VERSION
*
      INTEGER MAJOR, MINOR, PATCH
*
      CALL PILAVER ( MAJOR, MINOR, PATCH )
      WRITE(*,  FMT = 9999 ) MAJOR, MINOR, PATCH
*
 9999 FORMAT(I1,'.',I1,'.',I1)
      END\n""")

        ldflg = self.config.scalapacklib+' '+self.config.lapacklib+' '+self.config.blaslib+' '+self.config.ldflags_fc+' -lm'
        ccomm = self.config.fc+' -o tmpf '+'tmpf.f '+ldflg
        (output, error, retz) = runShellCommand(ccomm)

        if(retz != 0):
          print 'error is:\n','*'*40,'\n',ccomm,'\n',error,'\n','*'*40
        else:
          comm = './tmpf'
          (output, error, retz) = runShellCommand(comm)
          if(retz != 0):
            print 'cannot get ScaLAPACK version number.'
            print 'error is:\n','*'*40,'\n',comm,'\n',error,'\n','*'*40
          else:
            print output,
          killfiles(['tmpf'])
        print 'Installation of ScaLAPACK successful.'
        print '(log is in ',fulllog,')'
		
        if self.testing == 1:
            filename=os.path.join(savecwd,'log/sca_testing')
            myfile = open(filename, 'w')

            print 'Compiling test routines...',
            sys.stdout.flush()
            comm = self.make+' exe'
            (output, error, retz) = runShellCommand(comm)
            myfile.write(output+error)
            if(retz != 0):
                print '\n\nScaLAPACK: error building ScaLAPACK test routines'
                print 'stderr:\n','*'*40,'\n',error,'\n','*'*40
                writefile(os.path.join(savecwd,'log/scalog'), output+error)
                sys.exit()

            print 'done'

            # TESTING
            
            print 'Running BLACS test routines...',
            sys.stdout.flush()
            os.chdir(os.path.join(os.getcwd(),'BLACS/TESTING'))
            a = ['xCbtest', 'xFbtest']
            for testing_exe in a:
               myfile.write('\n   *************************************************  \n')
               myfile.write('   ***                   OUTPUT BLACS TESTING '+testing_exe+'                   ***  \n')
               myfile.write('   *************************************************  \n')
               comm = self.config.mpirun+' -np 4 ./'+testing_exe
               (output, error, retz) = runShellCommand(comm)
               myfile.write(output+error)
               if(retz != 0):
               # This is normal to exit in Error for the BLACS TESTING (good behaviour)
               # So we are going to check that the output have the last line of the testing : DONE BLACS_GRIDEXIT
                  if output.find('DONE BLACS_GRIDEXIT')==-1:
                     print '\n\nBLACS: error running BLACS test routines '+testing_exe
                     print '\n\nBLACS: Command '+comm
                     print 'stderr:\n','*'*40,'\n',error,'\n','*'*40
                     myfile.close()
                     sys.exit()
            os.chdir(os.path.join(os.getcwd(),'../..'))            
            print 'done'
            
            print 'Running PBLAS test routines...',
            sys.stdout.flush()
            os.chdir(os.path.join(os.getcwd(),'PBLAS/TESTING'))
            a = ['xcpblas1tst', 'xdpblas1tst', 'xspblas1tst', 'xzpblas1tst']
            a.extend(['xcpblas2tst', 'xdpblas2tst', 'xspblas2tst', 'xzpblas2tst'])
            a.extend(['xcpblas3tst', 'xdpblas3tst', 'xspblas3tst', 'xzpblas3tst'])
            for testing_exe in a:
               myfile.write('\n   *************************************************  \n')
               myfile.write('   ***                   OUTPUT PBLAS TESTING '+testing_exe+'                   ***  \n')
               myfile.write('   *************************************************  \n')
               comm = self.config.mpirun+' -np 4 ./'+testing_exe
               (output, error, retz) = runShellCommand(comm)
               myfile.write(output+error)
               if(retz != 0):
                  print '\n\nPBLAS: error running PBLAS test routines '+testing_exe
                  print '\n\nPBLAS: Command '+comm
                  print 'stderr:\n','*'*40,'\n',error,'\n','*'*40
                  myfile.close()
                  sys.exit()
            os.chdir(os.path.join(os.getcwd(),'../..'))            
            print 'done'

            print 'Running REDIST test routines...',
            sys.stdout.flush()
            os.chdir(os.path.join(os.getcwd(),'REDIST/TESTING'))
            a = ['xcgemr','xctrmr','xdgemr','xdtrmr','xigemr','xitrmr','xsgemr','xstrmr','xzgemr','xztrmr']
            for testing_exe in a:
               myfile.write('\n   *************************************************  \n')
               myfile.write('   ***                   OUTPUT REDIST TESTING '+testing_exe+'                   ***  \n')
               myfile.write('   *************************************************  \n')
               comm = self.config.mpirun+' -np 4 ./'+testing_exe
               (output, error, retz) = runShellCommand(comm)
               myfile.write(output+error)
               if(retz != 0):
                  print '\n\nREDIST: error running REDIST test routines '+testing_exe
                  print '\n\nREDIST: Command '+comm
                  print 'stderr:\n','*'*40,'\n',error,'\n','*'*40
                  myfile.close()
                  sys.exit()
            os.chdir(os.path.join(os.getcwd(),'../..'))            
            print 'done'

            print 'Running (some) ScaLAPACK test routines...',
            sys.stdout.flush()
            os.chdir(os.path.join(os.getcwd(),'TESTING'))
            a = ['xslu', 'xdlu', 'xclu', 'xzlu']
            a.extend(['xsqr', 'xdqr', 'xcqr', 'xzqr'])
            a.extend(['xsinv', 'xdinv', 'xcinv', 'xzinv'])
            a.extend(['xsllt', 'xdllt', 'xcllt', 'xzllt'])
            a.extend(['xshrd', 'xdhrd', 'xchrd', 'xzhrd'])
            a.extend(['xsls', 'xdls', 'xcls', 'xzls'])
            a.extend(['xssyevr', 'xdsyevr', 'xcheevr', 'xzheevr'])
            a.extend(['xshseqr', 'xdhseqr'])

            for testing_exe in a:
               myfile.write('\n   *************************************************  \n')
               myfile.write('   ***                   OUTPUT ScaLAPACK TESTING '+testing_exe+'                   ***  \n')
               myfile.write('   *************************************************  \n')
               comm = self.config.mpirun+' -np 4 ./'+testing_exe
               (output, error, retz) = runShellCommand(comm)
               myfile.write(output+error)
               if(retz != 0):
                  print '\n\nScaLAPACK: error running ScaLAPACK test routines '+testing_exe
                  print '\n\nScaLAPACK: Command '+comm
                  print 'stderr:\n','*'*40,'\n',error,'\n','*'*40
                  myfile.close()
                  sys.exit()
            os.chdir(os.path.join(os.getcwd(),'..'))
            print 'done'
            myfile.close()

        os.chdir(savecwd)
        print "ScaLAPACK is installed. Use it in moderation :-)"
