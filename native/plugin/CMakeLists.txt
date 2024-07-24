project(ProceduralExplorationGamePlugin)

file(GLOB_RECURSE srcs "src/*.cpp")

if(STATIC_ONLY)
    add_library(${PROJECT_NAME} SHARED MODULE
        ${srcs}
    )
    target_include_directories(${PROJECT_NAME} PUBLIC src)

    if(APPLE)
      target_link_options(${PROJECT_NAME} PRIVATE -undefined dynamic_lookup)
    endif()

    target_link_libraries(${PROJECT_NAME} ProceduralExplorationGameNativeCore)

    add_dependencies(${PROJECT_NAME} ProceduralExplorationGameNativeCore)
endif()

add_library(${PROJECT_NAME}_static STATIC
    ${srcs}
)
target_include_directories(${PROJECT_NAME}_static PUBLIC src)

target_link_libraries(${PROJECT_NAME}_static ProceduralExplorationGameNativeCore)

add_dependencies(${PROJECT_NAME}_static ProceduralExplorationGameNativeCore)