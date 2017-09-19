find_file(CONAN_COMMAND NAMES conan conan.exe PATHS $ENV{PATH} $ENV{CONAN_DIR})
if(CONAN_COMMAND)
  option(USE_CONAN "Use conan for dependency management." ON)
endif()

find_file(CONAN_BUILD_INFO conanbuildinfo.cmake NO_DEFAULT_PATH PATHS ${CMAKE_BINARY_DIR})
if(USE_CONAN AND NOT CONAN_BUILD_INFO)
  message(FATAL_ERROR "Error using conan: You need to execute 'conan install' before running cmake! Aborting.")
endif()

macro(conan_basic_setup)
  if(CONAN_EXPORTED)
    message(STATUS "Conan: called by CMake conan helper.")
  endif()
  conan_check_compiler        ()
  conan_set_find_library_paths()
  if(NOT "${ARGV0}" STREQUAL "TARGETS")
    message(STATUS "Conan: Using cmake global configuration.")
    conan_global_flags  ()
  else ()
    message(STATUS "Conan: Using cmake targets configuration.")
    conan_define_targets()
  endif()
  conan_set_rpath     ()
  conan_set_vs_runtime()
  conan_set_libcxx    ()
  conan_set_find_paths()
endmacro()
if   (USE_CONAN AND CONAN_BUILD_INFO)
  include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  conan_basic_setup(TARGETS)
endif()

macro(find_package_or_conan PACKAGE)
  # Parse arguments.
  set(OPTIONS)
  set(SINGLE_ARGS CONAN_NAME)
  set(MULTI_ARGS)
  cmake_parse_arguments(find_package_or_conan "${OPTIONS}" "${SINGLE_ARGS}" "${MULTI_ARGS}" ${ARGN})
  string(REPLACE ";" " " ADDITIONAL_PARAMS "${FIND_PACKAGE_OR_CONAN_UNPARSED_ARGUMENTS}")

  # Set default conan target name if CONAN_NAME was not specified.
  if   (find_package_or_conan_CONAN_NAME)
    set(CONAN_PACKAGE_NAME CONAN_PKG::${FIND_PACKAGE_OR_CONAN_CONAN_NAME})
  else ()
    set(CONAN_PACKAGE_NAME CONAN_PKG::${PACKAGE})
  endif()

  # Set target variable to be used in target_link_libraries accordingly.
  option(USE_CONAN_${PACKAGE} "Use conan for dependency management of ${PACKAGE}." ${USE_CONAN})
  if   (USE_CONAN AND USE_CONAN_${PACKAGE})
    set(CONAN_OR_CMAKE_${PACKAGE} ${CONAN_PACKAGE_NAME})
  else ()
    find_package(${PACKAGE} ${ADDITIONAL_PARAMS})
    set(CONAN_OR_CMAKE_${PACKAGE} ${PACKAGE})
  endif()
endmacro()
