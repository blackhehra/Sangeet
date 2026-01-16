# Stub CMakeLists.txt for flutter_blue_plus_winrt
# This disables the broken plugin on Windows

cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_blue_plus_winrt")
project(${PROJECT_NAME} LANGUAGES CXX)

# Build a minimal stub plugin
add_library(${PROJECT_NAME}_plugin SHARED
  "flutter_blue_plus_winrt_plugin.cpp"
)

# Apply standard settings
apply_standard_settings(${PROJECT_NAME}_plugin)

# Set preprocessor definition for export
target_compile_definitions(${PROJECT_NAME}_plugin PRIVATE FLUTTER_PLUGIN_IMPL)

# Link required libraries
target_include_directories(${PROJECT_NAME}_plugin INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PROJECT_NAME}_plugin PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PROJECT_NAME}_plugin PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled
set(flutter_blue_plus_winrt_bundled_libraries "" PARENT_SCOPE)
