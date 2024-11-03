cmake_minimum_required(VERSION 3.13)

include(${CLASSICO_DEFS})

setup_cc_options()

set(CMAKE_CXX_STANDARD 20)

str_from_env(BOOST_BINDIR)
set(CMAKE_MODULE_PATH ${BOOST_BINDIR}/conan)

include(${BOOST_BINDIR}/conan/conan_toolchain.cmake)

find_package(Boost 1.86.0)

set(SOURCES
    "src/main.cc")

add_executable(p1 ${SOURCES})

include_directories(${Boost_INCLUDE_DIRS})
target_link_libraries(p1 ${Boost_LIBRARIES})
