#!/usr/bin/python2
# -*- coding: utf-8 -*-

###
#
# @file setup.py
###
# -----------------------------------------
# ScaLAPACK installer
# University of Tennessee Knoxville
# October 16, 2007
# ----------------------------------------

import sys

VERSION_MAJOR = 1
VERSION_MINOR = 0
VERSION_MICRO = 3 

from script.blas        import Blas
from script.lapack      import Lapack
from script.scalapack   import Scalapack

import netlib

def main(argv):

  ### Store history of executed commands in config.log
  cmd = ""
  for arg in argv:
      cmd += arg+" "
  cmd += "\n"
  fp = open("history.log",'a')
  fp.write(cmd)
  fp.close()
  ### END

  config = netlib.Config((VERSION_MAJOR, VERSION_MINOR, VERSION_MICRO))

  scalapack = Scalapack(argv, config)

  if (scalapack.testing!= 0):
	Blas(config, scalapack);
	Lapack(config, scalapack);
       
  scalapack.resume()

  return 0

if "__main__" == __name__:
  sys.exit(main(sys.argv))
