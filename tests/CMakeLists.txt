# exclude certain files
# note the source dir on each 
set (tests_exclude "")

message(STATUS "running cmake in tests folder:\n")

message(STATUS "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "CMAKE_CURRENT_BINARY_DIR = ${CMAKE_CURRENT_BINARY_DIR}")
set(TEST_DATA_PATH "${CMAKE_CURRENT_SOURCE_DIR}/data")
configure_file(test_config.h.in test_config.h)
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# Build tests
gtsamAddTestsGlobAll(FUSESTests "test*.cpp" "${tests_exclude}" "${LIBS}" "${src_cpp_files}")
#message(STATUS "=================================== src_cpp_files = ${src_cpp_files}")


