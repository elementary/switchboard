set (LIB_VERSION 2.0)
set (LIB_SOVERSION 0)

######################
# lib PC file
######################
set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$") # You hear that? It's kittens being killed by the gods of cmake

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CONFIG_FILE})
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.pc)

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

vala_precompile (LIB_VALA_C ${CMAKE_PROJECT_NAME}
  ${LIB_SOURCE}
  PACKAGES
  ${LIB_PACKAGES}
  OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
  GENERATE_VAPI
  ${CMAKE_PROJECT_NAME}
  GENERATE_HEADER
  ${CMAKE_PROJECT_NAME}
)

add_definitions (${LIB_CFLAGS})
link_directories (${LIB_LIBRARY_DIRS})

add_library (${CMAKE_PROJECT_NAME} ${LINK_MODE} ${LIB_VALA_C})

set_target_properties (${CMAKE_PROJECT_NAME} PROPERTIES
  OUTPUT_NAME ${CMAKE_PROJECT_NAME}
  VERSION ${LIB_VERSION}
  SOVERSION ${LIB_SOVERSION}
)

target_link_libraries (${CMAKE_PROJECT_NAME} ${LIB_LIBRARIES})

if (BUILD_SHARED_LIBS)
  install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION lib)
  # Install lib stuffs
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.pc DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.vapi DESTINATION share/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.deps DESTINATION share/vala/vapi/)
  install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.h DESTINATION include/${CMAKE_PROJECT_NAME}/)
endif ()

# GObject Introspection
include(GObjectIntrospectionMacros)
add_target_gir (${CMAKE_PROJECT_NAME} Switchboard ${CMAKE_PROJECT_NAME}.h "${LIB_VALA_C}" "${LIB_CFLAGS}" 2.0 Gee-1.0 Peas-1.0 Gtk-3.0)
