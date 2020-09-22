######################################################################################################################
# Ubuntu and other basic stuff
######################################################################################################################

# 1)First things first
date
sudo apt update
echo "updating" >> siesta_install.log
sudo apt upgrade
sudo apt install python3  # this should already be installed for ubuntu (try which python3)
	# Check current version with python3 -V
sudo apt install python2
sudo apt install git

######################################################################################################################
# Basic compiler stuff
######################################################################################################################

#Note: We assume you are running all the commands below as an ordinary user (non-root), so we use sudo when required. That's because mpirun does NOT like to be executed as root.
# 2) 
sudo apt install build-essential g++ gfortran libreadline-dev m4 xsltproc -y
sudo apt install openmpi-common openmpi-bin libopenmpi-dev -y

######################################################################################################################
# SIESTA installation.
######################################################################################################################

#For installation of siesta do this
#2. Create required installation folders in the opt folder in ubuntu which are for optional binaries

SIESTA_DIR=/opt/siesta
OPENBLAS_DIR=/opt/openblas
SCALAPACK_DIR=/opt/scalapack 

sudo mkdir $SIESTA_DIR $OPENBLAS_DIR $SCALAPACK_DIR
# temporally loose permissions (we will revert later)
sudo chmod -R 777 $SIESTA_DIR $OPENBLAS_DIR $SCALAPACK_DIR

#3. Install prerequisite libraries
#In order to run siesta in parallel using MPI you need non-threaded blas and lapack libraries along with a standard scalapack library.


#3.1. Install single-threaded openblas library from source
#Note: apt installs a threaded version of openblas by default, I think this is not suitable for this MPI build of siesta.

cd $OPENBLAS_DIR

#Below is legacyinstallation for blas version 0.3.7 move over to the next block to install latest
#wget -O OpenBLAS.tar.gz https://ufpr.dl.sourceforge.net/project/openblas/v0.3.7/OpenBLAS%200.3.7%20version.tar.gz
#tar xzf OpenBLAS.tar.gz && rm OpenBLAS.tar.gz
#cd "$(find . -type d -name xianyi-OpenBLAS*)"
#make DYNAMIC_ARCH=0 CC=gcc FC=gfortran HOSTCC=gcc BINARY=64 INTERFACE=64 \
#  NO_AFFINITY=1 NO_WARMUP=1 USE_OPENMP=0 USE_THREAD=0 USE_LOCKING=1 LIBNAMESUFFIX=nonthreaded
#make PREFIX=$OPENBLAS_DIR LIBNAMESUFFIX=nonthreaded install
#cd $OPENBLAS_DIR && rm -rf "$(find $OPENBLAS_DIR -maxdepth 1 -type d -name xianyi-OpenBLAS*)"


#Below is the installation for blas version 0.3.10
wget -O OpenBLAS.tar.gz https://github.com/xianyi/OpenBLAS/archive/v0.3.10.tar.gz
tar xzf OpenBLAS.tar.gz && rm OpenBLAS.tar.gz
cd OpenBLAS-0.3.10
make DYNAMIC_ARCH=0 CC=gcc FC=gfortran HOSTCC=gcc BINARY=64 INTERFACE=64 \
  NO_AFFINITY=1 NO_WARMUP=1 USE_OPENMP=0 USE_THREAD=0 USE_LOCKING=1 LIBNAMESUFFIX=nonthreaded
make PREFIX=$OPENBLAS_DIR LIBNAMESUFFIX=nonthreaded install


# if proerly done you should get somehign like this  ### start
#make[1]: Leaving directory '/opt/openblas/OpenBLAS-0.3.10/exports'

# OpenBLAS build complete. (BLAS CBLAS LAPACK LAPACKE)

#  OS               ... Linux
#  Architecture     ... x86_64
#  BINARY           ... 64bit
#  C compiler       ... GCC  (cmd & version : gcc (Ubuntu 9.3.0-10ubuntu2) 9.3.0)
#  Fortran compiler ... GFORTRAN  (cmd & version : GNU Fortran (Ubuntu 9.3.0-10ubuntu2) 9.3.0)
#  Library Name     ... libopenblas_nonthreaded_nehalem-r0.3.10.a (Single-threading)

#To install the library, you can run "make PREFIX=/path/to/your/installation install".

# era@DESKTOP-9RR9BKR:/opt/openblas/OpenBLAS-0.3.10$ make PREFIX=$OPENBLAS_DIR LIBNAMESUFFIX=nonthreaded install
# make -j 12 -f Makefile.install install
#make[1]: Entering directory '/opt/openblas/OpenBLAS-0.3.10'
#Generating openblas_config.h in /opt/openblas/include
#Generating f77blas.h in /opt/openblas/include
#Generating cblas.h in /opt/openblas/include
#Copying LAPACKE header files to /opt/openblas/include
#Copying the static library to /opt/openblas/lib
#Copying the shared library to /opt/openblas/lib
#Generating openblas.pc in /opt/openblas/lib/pkgconfig
#Generating OpenBLASConfig.cmake in /opt/openblas/lib/cmake/openblas
#Generating OpenBLASConfigVersion.cmake in /opt/openblas/lib/cmake/openblas
#Install OK!
#make[1]: Leaving directory '/opt/openblas/OpenBLAS-0.3.10'
#era@DESKTOP-9RR9BKR:/opt/openblas/OpenBLAS-0.3.10$
### End

# 3.2. Install scalapack from source
mpiincdir="/usr/include/mpich"
if [ ! -d "$mpiincdir" ]; then mpiincdir="/usr/lib/x86_64-linux-gnu/openmpi/include" ; fi
cd $SCALAPACK_DIR
wget http://www.netlib.org/scalapack/scalapack_installer.tgz -O ./scalapack_installer.tgz
tar xf ./scalapack_installer.tgz
mkdir -p $SCALAPACK_DIR/scalapack_installer/build/download/
wget https://github.com/Reference-ScaLAPACK/scalapack/archive/v2.1.0.tar.gz -O $SCALAPACK_DIR/scalapack_installer/build/download/scalapack.tgz
cd ./scalapack_installer
#Before mnoving on open file setup.py in teh scalapack_installer folder and change interpreter to python2 (have to have it installed)
./setup.py --prefix $SCALAPACK_DIR --blaslib=$OPENBLAS_DIR/lib/libopenblas_nonthreaded.a \
  --lapacklib=$OPENBLAS_DIR/lib/libopenblas_nonthreaded.a --mpibindir=/usr/bin --mpiincdir=$mpiincdir
#Note: Answer 'b' if asked: 'Which BLAS library do you want to use ?'

# # if properly done you should get somehign like this  ### start
# ScaLAPACK installation completed.


# Your BLAS library is                     : /opt/openblas/lib/libopenblas_nonthreaded.a

# Your LAPACK library is                   : /opt/openblas/lib/libopenblas_nonthreaded.a

# Your BLACS/ScaLAPACK library is          : -L/opt/scalapack/lib -lscalapack

# Log messages are in the
# /opt/scalapack/scalapack_installer/build/log directory.

# The ouput of ScaLAPACK testing programs are in:
# /opt/scalapack/scalapack_installer/build/log/sca_testing

# The
# /opt/scalapack/scalapack_installer/build
# directory contains the source code of the libraries
# that have been installed. It can be removed at this time.
# ### End


#4. Install siesta from source

cd $SIESTA_DIR
wget -O siesta-master.tar.gz https://launchpad.net/siesta/4.1/4.1-b4/+download/siesta-4.1-b4.tar.gz
# wget https://gitlab.com/siesta-project/siesta/-/archive/master/siesta-master.tar.gz   # This is for the gitlab version
tar xzf ./siesta-master.tar.gz && rm ./siesta-master.tar.gz

#4.1. Install siesta library dependencies from source
#Install the fortran-lua-hook library (flook):

cd $SIESTA_DIR/siesta-master/Docs
wget -O flook-0.8.1.tar.gz https://github.com/ElectronicStructureLibrary/flook/archive/v0.8.1.tar.gz
(./install_flook.bash 2>&1) | tee install_flook.log
# Slight error here
# did not work with the latest install_flook.bash script had to copy over from the old script and repalced teh version number.

# got his for sucsessfull install ######
##########################
# Completed installation #
#    of flook package    #
#  and its dependencies  #
##########################


# Please add the following to the BOTTOM of your arch.make file

# INCFLAGS += -I/opt/siesta/siesta-master/Docs/build/flook/0.8.1/include
# LDFLAGS += -L/opt/siesta/siesta-master/Docs/build/flook/0.8.1/lib -Wl,-rpath=/opt/siesta/siesta-master/Docs/build/flook/0.8.1/lib
# LIBS += -lflookall -ldl
# COMP_LIBS += libfdict.a
# FPPFLAGS += -DSIESTA__FLOOK
## end


#Install netcdf dependency (required and slow, grab a coffee):

cd $SIESTA_DIR/siesta-master/Docs
wget https://zlib.net/zlib-1.2.11.tar.gz
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.0/src/hdf5-1.12.0.tar.bz2
wget -O netcdf-c-4.7.4.tar.gz https://github.com/Unidata/netcdf-c/archive/v4.7.4.tar.gz
wget -O netcdf-fortran-4.5.3.tar.gz https://github.com/Unidata/netcdf-fortran/archive/v4.5.3.tar.gz
(./install_netcdf4.bash 2>&1) | tee install_netcdf4.log

# got his for sucsessfull install ######
# +-------------------------------------------------------------+
# | Congratulations! You have successfully installed the netCDF |
# | Fortran libraries.                                          |
# |                                                             |
# | You can use script "nf-config" to find out the relevant     |
# | compiler options to build your application. Enter           |
# |                                                             |
# |     nf-config --help                                        |
# |                                                             |
# | for additional information.                                 |
# |                                                             |
# | CAUTION:                                                    |
# |                                                             |
# | If you have not already run "make check", then we strongly  |
# | recommend you do so. It does not take very long.            |
# |                                                             |
# | Before using netCDF to store important data, test your      |
# | build with "make check".                                    |
# |                                                             |
# | NetCDF is tested nightly on many platforms at Unidata       |
# | but your platform is probably different in some ways.       |
# |                                                             |
# | If any tests fail, please see the netCDF web site:          |
# | http://www.unidata.ucar.edu/software/netcdf/                |
# |                                                             |
# | NetCDF is developed and maintained at the Unidata Program   |
# | Center. Unidata provides a broad array of data and software |
# | tools for use in geoscience education and research.         |
# | http://www.unidata.ucar.edu                                 |
# +-------------------------------------------------------------+

# make[3]: Leaving directory '/opt/siesta/siesta-master/Docs/netcdf-fortran-4.5.3/build'
# make[2]: Leaving directory '/opt/siesta/siesta-master/Docs/netcdf-fortran-4.5.3/build'
# make[1]: Leaving directory '/opt/siesta/siesta-master/Docs/netcdf-fortran-4.5.3/build'
# Completed installing Fortran NetCDF library

#########################
# Completed installation #
#   of NetCDF package    #
#  and its dependencies  #
##########################


# Please add the following to the BOTTOM of your arch.make file

# INCFLAGS += -I/opt/siesta/siesta-master/Docs/build/include
# LDFLAGS += -L/opt/siesta/siesta-master/Docs/build/lib -Wl,-rpath,/opt/siesta/siesta-master/Docs/build/lib
# LIBS += -lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lz
# COMP_LIBS += libncdf.a libfdict.a
# FPPFLAGS += -DCDF -DNCDF -DNCDF_4
## end

#If anything goes wrong in this step you can check the install_netcdf4.log log file.

# Install siesta
#Recommended to use the tutorial at which this is based on. This file has mutiple more edits compared to the tutorial that make the installaion work with newer libraries


cd $SIESTA_DIR/siesta-master/Obj
wget -O arch.make https://raw.githubusercontent.com/bgeneto/siesta-gcc-mpi/master/gcc-mpi-arch.make

# Now replace the above additions to the arch.make file into the newly downloaded arch.make file.

cd $SIESTA_DIR/siesta-master/Obj
sh ../Src/obj_setup.sh
make OBJDIR=Obj

#5. Revert to default permissions and ownership
#Just in case...

sudo chown -R root:root $SIESTA_DIR $OPENBLAS_DIR $SCALAPACK_DIR
sudo chmod -R 755 $SIESTA_DIR $OPENBLAS_DIR $SCALAPACK_DIR

#6. Test siesta
#Let's copy siesta Test directory to our home (where we have all necessary permissions):

# mkdir -p $HOME/siesta/siesta-master
# rsync -a $SIESTA_DIR/siesta-master/Tests/ $HOME/siesta/siesta-master/Tests/

# #Now create a symbolic link to siesta executable

# cd $HOME/siesta/siesta-master
# ln -s $SIESTA_DIR/siesta-master/Obj/siesta

# # Finally run some test 


# cd $HOME/siesta/siesta-master/Tests/h2o_dos/
# make

# # We should see the following message:

# # ===> SIESTA finished successfully

date









