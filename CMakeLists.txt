#CMake minimum requirement 
get_directory_property(HAS_PARENT PARENT_DIRECTORY)
if(HAS_PARENT)
    set(KITTEN_TOPLEVEL_PROJECT OFF)
else()
    set(KITTEN_TOPLEVEL_PROJECT ON)
endif()

cmake_minimum_required(VERSION 3.19 FATAL_ERROR)

#Project name 
set(project_name "KittenLBVH")#<TODO> change this to the name of your project 
project(${project_name} LANGUAGES CXX C CUDA)  

option(KITTEN_LBVH_SHARED_LIBS "Build as shared library" OFF)

#default build type is Release
if (CMAKE_BUILD_TYPE STREQUAL "")
    set(CMAKE_BUILD_TYPE Release)
endif ()

# Direct all output to /bin directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)

# glm
include(FetchContent)
FetchContent_Declare(glm
    GIT_REPOSITORY https://github.com/g-truc/glm.git
    GIT_TAG        master
)
FetchContent_Populate(glm)
add_subdirectory(${glm_SOURCE_DIR})

# Auto-detect GPU architecture
include("cmake/AutoDetectCudaArch.cmake")

# CUDA and C++ compiler flags
set(cxx_flags 
	$<$<CXX_COMPILER_ID:MSVC>:-D_SCL_SECURE_NO_WARNINGS /openmp /std:c++17> #<TODO> Add MSVC-specific compiler flags here
	$<$<CXX_COMPILER_ID:GNU>:-Wall -m64 -fopenmp -O3 -std=c++17>            #<TODO> Add GCC compiler flags here
	$<$<CXX_COMPILER_ID:Clang>:-Wall -m64 -fopenmp -O3 -std=c++17>          #<TODO> Add Clang compiler flags here
	)

set(MSVC_XCOMPILER_FLAGS "/openmp /std:c++17")
set(cuda_flags
    $<$<CXX_COMPILER_ID:GNU>:-Xcompiler -Wall -fopenmp -O3>
	$<$<CXX_COMPILER_ID:Clang>:-Xcompiler -Wall -fopenmp -O3>
	$<$<CXX_COMPILER_ID:MSVC>:-Xcompiler ${MSVC_XCOMPILER_FLAGS}>
    -Xcudafe=--display_error_number    
	-lineinfo	
	--expt-extended-lambda	
	-use_fast_math		
    $<$<CXX_COMPILER_ID:GNU>:-O3>	
	--expt-relaxed-constexpr	
    -Xptxas -warn-spills -res-usage   
	--ptxas-options=-v	
    #-G	
)
add_library(developer_flags INTERFACE)
target_compile_options(developer_flags INTERFACE
    $<$<COMPILE_LANGUAGE:CXX>:${cxx_flags}>
    $<$<COMPILE_LANGUAGE:CUDA>:${cuda_flags}>
)
target_include_directories(developer_flags INTERFACE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

target_compile_features(developer_flags INTERFACE cxx_std_17)

#OpenMP
find_package(OpenMP)
if(OpenMP_CXX_FOUND)
    target_link_libraries(developer_flags INTERFACE OpenMP::OpenMP_CXX)
endif()

enable_testing()

set(lib_name "KittenLBVH")

#GLOB source files 
set(KittenSrc 
	${CMAKE_CURRENT_SOURCE_DIR}/include/KittenLBVH/Bound.h
	${CMAKE_CURRENT_SOURCE_DIR}/include/KittenLBVH/Common.h
	${CMAKE_CURRENT_SOURCE_DIR}/include/KittenLBVH/lbvh.cu
	${CMAKE_CURRENT_SOURCE_DIR}/include/KittenLBVH/lbvh.cuh)

#Executable
if(${KITTEN_LBVH_SHARED_LIBS})
	add_library(${lib_name} SHARED ${KittenSrc})
else()
	add_library(${lib_name} STATIC ${KittenSrc})
endif()

target_include_directories(${lib_name} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/")

#Pass the flags to the library
target_link_libraries( ${lib_name}
	PUBLIC $<BUILD_INTERFACE:developer_flags> glm::glm
)

if(${KITTEN_TOPLEVEL_PROJECT})	
	add_executable(TestKittenLBVH ${CMAKE_CURRENT_SOURCE_DIR}/main.cu)	
	target_link_libraries( TestKittenLBVH 
		${lib_name}
		$<BUILD_INTERFACE:developer_flags>)
endif()