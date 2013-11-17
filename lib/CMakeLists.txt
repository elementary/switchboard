set (LIB_VERSION 2.0)
set (LIB_SOVERSION 0)

######################
# Set Variables
######################

set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$") # You hear that? It's kittens being killed by the gods of cmake
set (LIB_NAME ${CMAKE_PROJECT_NAME}-${LIB_VERSION})

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CONFIG_FILE})
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}.pc)

set (LIB_SOURCE
  ${CONFIG_FILE}
  Plug.vala
  PlugsManager.vala
)

if  (BUILD_SHARED_LIBS)
  set (LINK_MODE SHARED)
else ()
  set (LINK_MODE STATIC)
endif ()

######################
# Generate .c, .vapi, .gir and .h
######################

vala_precompile (LIB_VALA_C ${LIB_NAME}
  ${LIB_SOURCE}
  PACKAGES
  ${LIB_PACKAGES}
  OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
  GENERATE_VAPI
  ${LIB_NAME}
  GENERATE_HEADER
  ${CMAKE_PROJECT_NAME}
  GENERATE_GIR
  Switchboard-${LIB_VERSION}
)

######################
# Include definitions
######################

add_definitions (${LIB_CFLAGS})
link_directories (${LIB_LIBRARY_DIRS})

add_library (${LIB_NAME} ${LINK_MODE} ${LIB_VALA_C})

set_target_properties (${LIB_NAME} PROPERTIES
  OUTPUT_NAME ${LIB_NAME}
  VERSION ${LIB_VERSION}
  SOVERSION ${LIB_SOVERSION}
)

target_link_libraries (${LIB_NAME} ${LIB_LIBRARIES})

######################
# Installation
######################

if (BUILD_SHARED_LIBS)
  install (TARGETS ${LIB_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
  # Install lib stuffs
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}.pc DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}.vapi DESTINATION ${CMAKE_INSTALL_PREFIX}/share/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/Switchboard-${LIB_VERSION}.gir DESTINATION ${CMAKE_INSTALL_PREFIX}/share/gir-1.0/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/Switchboard-${LIB_VERSION}.typelib DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/girepository-1.0/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${LIB_NAME}.deps DESTINATION ${CMAKE_INSTALL_PREFIX}/share/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.h DESTINATION ${CMAKE_INSTALL_PREFIX}/include/${LIB_NAME}/)
endif ()
