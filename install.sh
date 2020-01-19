#!/bin/bash

set -e

home=$PWD

#netcdf=https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.3.tar.gz
netcdf=https://github.com/Unidata/netcdf-c/archive/v4.3.3.1.tar.gz
netcdf_dir=netcdf-c-4.3.3.1

boost=https://netix.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
boost_dir=boost_1_59_0

nii_dir=nii/CURRENNT_codes

mark=.done-netcdf
if [ ! -f $mark ]; then
  if [ ! -f $(basename $netcdf) ]; then
    wget $netcdf || exit 1
  fi
  echo 'Unpacking NetCDF source files'
  dir=$PWD/$netcdf_dir
  [ -d $dir ] && rm -r $dir
  tar -xf $(basename $netcdf) || exit 1
  echo 'Building NetCDF'
  build=$dir/build
  cd $dir
  ./configure --disable-netcdf-4 --prefix=$build || exit 1
  make -j $(nproc) || exit 1
  make install || exit 1
  cd $home
  touch $mark
fi
netcdf_lib=$PWD/$netcdf_dir/build/lib

mark=.done-boost
if [ ! -f $mark ]; then
  if [ ! -f $(basename $boost) ]; then
    wget $boost || exit 1
  fi
  echo 'Unpacking boost source files'
  dir=$PWD/$boost_dir
  [ -d $dir ] && rm -r $dir
  tar -xf $(basename $boost) || exit 1
  echo 'Building boost libraries'
  build=$dir/build
  cd $dir
  ./bootstrap.sh --with-libraries=program_options,filesystem,system,random,thread || exit 1
  ./b2 --prefix=$build || exit 1
  cd $home
  touch $mark
fi
boost_root=$PWD/$boost_dir

mark=.done-nii
if [ ! -f $mark ]; then
  echo 'Building nii'
  cp nii_cmake/CMakeLists.txt $nii_dir
  dir=$PWD/$nii_dir/build
  [ -d $dir ] && rm -r $dir
  mkdir -p $dir || exit 1
  cd $dir
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBOOST_ROOT=$boost_root \
    -DNETCDF_LIB=$netcdf_lib || exit 1
  make -j $(npoc) || exit 1
  cd $home
  touch $mark
fi

echo Done
