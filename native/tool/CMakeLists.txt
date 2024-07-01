project(ProceduralExplorationGameNativeCoreTool)

file(GLOB_RECURSE tool_srcs "src/*.cpp")

add_executable(${PROJECT_NAME}
    ${tool_srcs}
)

add_dependencies(${PROJECT_NAME} ProceduralExplorationGameNativeCore_static)

target_link_libraries(${PROJECT_NAME} ProceduralExplorationGameNativeCore_static)