# set(CMAKE_CXX_STANDARD 20)

file(GLOB SOURCES "lib1.cc")

add_library(lib1 STATIC ${SOURCES})
target_compile_features(lib1 PUBLIC cxx_std_20)

include_directories(${root})
