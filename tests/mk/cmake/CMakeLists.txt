cmake_minimum_required(VERSION 3.13)

include(${CLASSICO_DEFS})

#----------------------------------------------------------------------------------------------

# set(CMAKE_CXX_STANDARD 20)

project(p1)

setup_cc_options()

#----------------------------------------------------------------------------------------------

add_compile_definitions(
    _GNU_SOURCE)

include_directories(
    ${root}/src
    ${root})

set(SOURCES
    "src/main.cc")

add_executable(p1 ${SOURCES})
target_compile_features(p1 PUBLIC cxx_std_20)

#----------------------------------------------------------------------------------------------

set_target_properties(p1 PROPERTIES LINKER_LANGUAGE CXX)

add_subdirectory(lib1)

target_link_libraries(p1 lib1)

#----------------------------------------------------------------------------------------------
