#
# Toolchain file for
#
# Generic build environment
#
# This is a generic template which probably will not work on your system out of the box. You should
# either modify it or override the variables via command line options to make it to
# work. Alternatively, have a look at the specialized toolchain files in this folder as they may
# give you a better starting point for your build environment.
#
# Notes:
#
#  * CMake format: Command line options (e.g. compiler flags) space separated, other kind
#    of lists semicolon separated.
#
#  * Variables containing library search paths are empty by default. The CMAKE_PREFIX_PATH
#    environment variable should be set up correctly, so that CMake can find those libraries
#    automatically. If that is not the case, override those variables to add search paths
#    manually


#
# Fortran compiler settings
#
set(Fortran_FLAGS "${CMAKE_Fortran_FLAGS}"
  CACHE STRING "Build type independent Fortran compiler flags")

set(Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE}"
  CACHE STRING "Fortran compiler flags for Release build")

set(Fortran_FLAGS_RELWITHDEBINFO "${CMAKE_Fortran_FLAGS_RELWITHDEBINFO}"
  CACHE STRING "Fortran compiler flags for Release build")

set(Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG}"
  CACHE STRING "Fortran compiler flags for Debug build")

# Use intrinsic Fortran 2008 erf/erfc functions
set(INTERNAL_ERFC CACHE BOOL 0)


#
# External libraries
#

# NOTE: Libraries with CMake export files (e.g. ELSI and if the HYBRID_CONFIG_METHODS variable
# contains the "Find" method also libNEGF, libMBD, ScalapackFx and MpiFx) are included by searching
# for the CMake export file in the paths defined in the CMAKE_PREFIX_PATH **environment**
# variable. Make sure your CMAKE_PREFIX_PATH variable is set up accordingly.

# LAPACK and BLAS
#set(LAPACK_LIBRARY "lapack;blas" CACHE STRING "LAPACK and BLAS libraries to link")
#set(LAPACK_LIBRARY_DIR "" CACHE STRING
#  "Directories where LAPACK and BLAS libraries can be found")
