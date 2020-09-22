#!/bin/bash

# Installation script for zlib, hdf5, netcdf-c and netcdf-fortran
# with complete CDF-4 support (in serial).
# This installation script has been written by:
#  Nick R. Papior, 2016-2018.
#
# The author takes no responsibility of damage done to your hardware or
# software. It is up to YOU that the script executes the correct commands.
#
# This script is released under the LGPL license.

# VERY BASIC installation script of required libraries
# for installing these packages:
#   zlib-1.2.11
#   hdf5-1.8.21
#   netcdf-c-4.6.1
#   netcdf-fortran-4.4.4
# If you want to change your compiler version you should define the
# global variables that are used for the configure scripts to grab the
# compiler, they should be CC and FC. Also if you want to compile with
# different flags you should export those variables; CFLAGS, FFLAGS.

# If you have downloaded other versions edit these version strings
z_v=1.2.11
h_v=1.12.0
nc_v=4.7.4
nf_v=4.5.3

# Install path, change accordingly
# You can change this variable to control the installation path
# If you want the installation path to be a "packages" folder in
# your home directory, change to this:
# ID=$HOME/packages
if [ -z $PREFIX ]; then
    ID=$(pwd)/build
else
    ID=$PREFIX
fi

echo "Installing libraries in folder: $ID"
mkdir -p $ID

# First we check that the user have downloaded the files
function file_exists {
    if [ ! -e $(pwd)/$1 ]; then
	echo "I could not find file $1..."
	echo "Please download the file and place it in this folder:"
	echo " $(pwd)"
	exit 1
    fi
}

# Check for function $?
function retval {
    local ret=$1
    local info="$2"
    shift 2
    if [ $ret -ne 0 ]; then
	echo "Error: $ret"
	echo "$info"
	exit 1
    fi
}

file_exists zlib-${z_v}.tar.gz
file_exists hdf5-${h_v}.tar.bz2
file_exists netcdf-c-${nc_v}.tar.gz
file_exists netcdf-fortran-${nf_v}.tar.gz
unset file_exists

#################
# Install z-lib #
#################
[ -d $ID/zlib/${z_v}/lib64 ] && zlib_lib=lib64 || zlib_lib=lib
if [ ! -d $ID/zlib/${z_v}/$zlib_lib ]; then
    tar xfz zlib-${z_v}.tar.gz
    cd zlib-${z_v}
    ./configure --prefix $ID/zlib/${z_v}
    retval $? "zlib config"
    make
    retval $? "zlib make"
    make test 2>&1 | tee zlib.test
    retval $? "zlib make test"
    make install
    retval $? "zlib make install"
    mv zlib.test $ID/zlib/${z_v}/
    cd ../
    rm -rf zlib-${z_v}
    echo "Completed installing zlib"
    [ -d $ID/zlib/${z_v}/lib64 ] && zlib_lib=lib64 || zlib_lib=lib
else
    echo "zlib directory already found."
fi

################
# Install hdf5 #
################
[ -d $ID/hdf5/${h_v}/lib64 ] && hdf5_lib=lib64 || hdf5_lib=lib
if [ ! -d $ID/hdf5/${h_v}/$hdf5_lib ]; then
    tar xfj hdf5-${h_v}.tar.bz2
    cd hdf5-${h_v}
    mkdir build ; cd build
    ../configure --prefix=$ID/hdf5/${h_v} \
	--enable-shared --enable-static \
	--enable-fortran --with-zlib=$ID/zlib/${z_v} \
	LDFLAGS="-L$ID/zlib/${z_v}/$zlib_lib -Wl,-rpath=$ID/zlib/${z_v}/$zlib_lib"
    retval $? "hdf5 configure"
    make
    retval $? "hdf5 make"
    make check-s 2>&1 | tee hdf5.test
    retval $? "hdf5 make check-s"
    make install
    retval $? "hdf5 make install"
    mv hdf5.test $ID/hdf5/${h_v}/
    cd ../../
    rm -rf hdf5-${h_v}
    echo "Completed installing hdf5"
    [ -d $ID/hdf5/${h_v}/lib64 ] && hdf5_lib=lib64 || hdf5_lib=lib
else
    echo "hdf5 directory already found."
fi

####################
# Install NetCDF-C #
####################
[ -d $ID/netcdf/${nc_v}/lib64 ] && cdf_lib=lib64 || cdf_lib=lib
if [ ! -d $ID/netcdf/${nc_v}/$cdf_lib ]; then
    tar xfz netcdf-c-${nc_v}.tar.gz
    cd netcdf-c-${nc_v}
    mkdir build ; cd build
    ../configure --prefix=$ID/netcdf/${nc_v} \
	--enable-shared --enable-static \
	--enable-netcdf-4 --disable-dap \
	CPPFLAGS="-I$ID/hdf5/${h_v}/include -I$ID/zlib/${z_v}/include" \
	LDFLAGS="-L$ID/hdf5/${h_v}/$hdf5_lib -Wl,-rpath=$ID/hdf5/${h_v}/$hdf5_lib \
-L$ID/zlib/${z_v}/$zlib_lib -Wl,-rpath=$ID/zlib/${z_v}/$zlib_lib"
    retval $? "netcdf configure"
    make
    retval $? "netcdf make"
    make install
    retval $? "netcdf make install"
    cd ../../
    rm -rf netcdf-c-${nc_v}
    echo "Completed installing C NetCDF library"
    [ -d $ID/netcdf/${nc_v}/lib64 ] && cdf_lib=lib64 || cdf_lib=lib
else
    echo "netcdf directory already found."
fi

##########################
# Install NetCDF-Fortran #
##########################
if [ ! -e $ID/netcdf/${nc_v}/$cdf_lib/libnetcdff.a ]; then
    tar xfz netcdf-fortran-${nf_v}.tar.gz
    cd netcdf-fortran-${nf_v}
    mkdir build ; cd build
    ../configure CPPFLAGS="-DgFortran -I$ID/zlib/${z_v}/include \
	-I$ID/hdf5/${h_v}/include -I$ID/netcdf/${nc_v}/include" \
	LIBS="-L$ID/zlib/${z_v}/$zlib_lib -Wl,-rpath=$ID/zlib/${z_v}/$zlib_lib \
	-L$ID/hdf5/${h_v}/$hdf5_lib -Wl,-rpath=$ID/hdf5/${h_v}/$hdf5_lib \
	-L$ID/netcdf/${nc_v}/$cdf_lib -Wl,-rpath=$ID/netcdf/${nc_v}/$cdf_lib \
	-lnetcdf -lhdf5hl_fortran -lhdf5_fortran -lhdf5_hl -lhdf5 -lz" \
	--prefix=$ID/netcdf/${nc_v} --enable-static --enable-shared
    retval $? "netcdf-fortran configure"
    make
    retval $? "netcdf-fortran make"
    make check 2>&1 | tee check.fortran.serial
    retval $? "netcdf-fortran make check"
    make install
    retval $? "netcdf-fortran make install"
    mv check.fortran.serial $ID/netcdf/${nc_v}/
    cd ../../
    rm -rf netcdf-fortran-${nf_v}
    echo "Completed installing Fortran NetCDF library"
else
    echo "netcdf-fortran library already found."
fi

##########################
# Completed installation #
##########################

echo ""
echo "##########################"
echo "# Completed installation #"
echo "#   of NetCDF package    #"
echo "#  and its dependencies  #"
echo "##########################"
echo ""
echo ""

echo "Please add the following to the BOTTOM of your arch.make file"
echo ""
echo "INCFLAGS += -I$ID/netcdf/${nc_v}/include"
echo "LDFLAGS += -L$ID/zlib/${z_v}/$zlib_lib -Wl,-rpath=$ID/zlib/${z_v}/$zlib_lib"
echo "LDFLAGS += -L$ID/hdf5/${h_v}/$hdf5_lib -Wl,-rpath=$ID/hdf5/${h_v}/$hdf5_lib"
echo "LDFLAGS += -L$ID/netcdf/${nc_v}/$cdf_lib -Wl,-rpath=$ID/netcdf/${nc_v}/$cdf_lib"
echo "LIBS += -lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lz"
echo "COMP_LIBS += libncdf.a libfdict.a"
echo "FPPFLAGS += -DCDF -DNCDF -DNCDF_4"
echo ""