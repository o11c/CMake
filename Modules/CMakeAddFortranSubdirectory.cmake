# - Use MinGW gfortran from VS if a fortran compiler is not found.
# The 'add_fortran_subdirectory' function adds a subdirectory
# to a project that contains a fortran only sub-project. The module
# will check the current compiler and see if it can support fortran.
# If no fortran compiler is found and the compiler is MSVC, then
# this module will find the MinGW gfortran.  It will then use
# an external project to build with the MinGW tools.  It will also
# create imported targets for the libraries created.  This will only
# work if the fortran code is built into a dll, so BUILD_SHARED_LIBS
# is turned on in the project.  In addition the GNUtoMS option is set
# to on, so that the MS .lib files are created.
# Usage is as follows:
# cmake_add_fortran_subdirectory(
#   <subdir>                 # name of subdirectory
#    PROJECT <project_name>  # project name in sbudir toplevel CMakeLists.txt
#  ARCHIVE_DIR <dir>         # .lib location relative to root binary tree (lib)
#  RUNTIME_DIR <dir>         # .dll location relative to root binary tree (bin)
#  LIBRARIES lib2 lib2    # names of libraries created and exported
#  LINK_LIBRARIES            # link interface libraries for LIBRARIES
#   LINK_LIBS <lib1>  <dep1> <dep2> ... <depN>
#   LINK_LIBS <lib2> <dep1> <dep2> ... <depN>
#  CMAKE_COMMAND_LINE        # extra command line flags to pass to cmake
#   )
#

#=============================================================================
# Copyright 2002-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)


set(_MS_MINGW_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
include(CheckFortran)
include(ExternalProject)
include(CMakeParseArguments)

function(_setup_mingw_config_and_build source_dir)
  find_program(MINGW_GFORTRAN NAMES gfortran
    HINTS
    c:/MinGW/bin
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\MinGW;InstallLocation]/bin" )
  if(NOT MINGW_GFORTRAN)
    message(FATAL_ERROR
      "gfortran not found, please install MinGW with the gfortran option."
      "Or set the cache variable MINGW_GFORTRAN to the full path. "
      " This is required to build")
  endif()
  execute_process(COMMAND ${MINGW_GFORTRAN} -v ERROR_VARIABLE out)
  if(NOT "${out}" MATCHES "Target:.*mingw32")
    message(FATAL_ERROR "Non-MinGW gfortran found: ${MINGW_GFORTRAN}\n"
      "output from -v [${out}]\n"
      "set MINGW_GFORTRAN to the path to MinGW fortran.")
  endif()
  get_filename_component(MINGW_PATH ${MINGW_GFORTRAN} PATH)
  file(TO_NATIVE_PATH "${MINGW_PATH}" MINGW_PATH)
  string(REPLACE "\\" "\\\\" MINGW_PATH "${MINGW_PATH}")
  configure_file(${_MS_MINGW_SOURCE_DIR}/config_mingw.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/config_mingw.cmake @ONLY)
  configure_file(${_MS_MINGW_SOURCE_DIR}/build_mingw.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/build_mingw.cmake @ONLY)
endfunction()

function(_add_fortran_library_link_interface library depend_library)
  set_target_properties(${library} PROPERTIES
    IMPORTED_LINK_INTERFACE_LIBRARIES_NOCONFIG "${depend_library}")
endfunction()


function(cmake_add_fortran_subdirectory subdir)
  # if we are not using MSVC without fortran support
  # then just use the usual add_subdirectory to build
  # the fortran library
  if(NOT (MSVC AND (NOT CMAKE_Fortran_COMPILER)))
    add_subdirectory(${subdir})
    return()
  endif()

  # if we have MSVC without Intel fortran then setup
  # external projects to build with mingw fortran

  # Parse arguments to function
  set(oneValueArgs PROJECT ARCHIVE_DIR RUNTIME_DIR)
  set(multiValueArgs LIBRARIES LINK_LIBRARIES CMAKE_COMMAND_LINE)
  cmake_parse_arguments(ARGS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  set(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/${subdir}")
  set(project_name "${ARGS_PROJECT}")
  set(library_dir "${ARGS_ARCHIVE_DIR}")
  set(binary_dir "${ARGS_RUNTIME_DIR}")
  set(libraries ${ARGS_LIBRARIES})
  # use the same directory that add_subdirectory would have used
  set(build_dir "${CMAKE_CURRENT_BINARY_DIR}/${subdir}")
  # create build and configure wrapper scripts
  _setup_mingw_config_and_build(${source_dir})
  # create the external project
  externalproject_add(${project_name}_build
    SOURCE_DIR ${source_dir}
    BINARY_DIR ${build_dir}
    CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -P ${CMAKE_CURRENT_BINARY_DIR}/config_mingw.cmake
    BUILD_COMMAND ${CMAKE_COMMAND}
    -P ${CMAKE_CURRENT_BINARY_DIR}/build_mingw.cmake
    INSTALL_COMMAND ""
    )
  # make the external project always run make with each build
  externalproject_add_step(${project_name}_build forcebuild
    COMMAND ${CMAKE_COMMAND}
    -E remove
    ${CMAKE_CURRENT_BUILD_DIR}/${project_name}-prefix/src/${project_name}-stamp/lapack-build
    DEPENDEES configure
    DEPENDERS build
    ALWAYS 1
    )
  # create imported targets for all libraries
  foreach(lib ${libraries})
    add_library(${lib} SHARED IMPORTED)
    set_property(TARGET ${lib} APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
    set_target_properties(${lib} PROPERTIES
      IMPORTED_IMPLIB_NOCONFIG
      "${build_dir}/${library_dir}/lib${lib}.lib"
      IMPORTED_LOCATION_NOCONFIG
      "${build_dir}/${binary_dir}/lib${lib}.dll"
      )
    add_dependencies(${lib} ${project_name}_build)
  endforeach()

  # now setup link libraries for targets
  set(start FALSE)
  set(target)
  foreach(lib ${ARGS_LINK_LIBRARIES})
    if("${lib}" STREQUAL "LINK_LIBS")
      set(start TRUE)
    else()
      if(start)
        if(DEFINED target)
          # process current target and target_libs
          _add_fortran_library_link_interface(${target} "${target_libs}")
          # zero out target and target_libs
          set(target)
          set(target_libs)
        endif()
        # save the current target and set start to FALSE
        set(target ${lib})
        set(start FALSE)
      else()
        # append the lib to target_libs
        list(APPEND target_libs "${lib}")
      endif()
    endif()
  endforeach()
  # process anything that is left in target and target_libs
  if(DEFINED target)
    _add_fortran_library_link_interface(${target} "${target_libs}")
  endif()
endfunction()