project (switchboard)
cmake_minimum_required (VERSION 2.8)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/)
#

# Base bits

#

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/switchboard")
set (GETTEXT_PACKAGE "switchboard")
set (RELEASE_NAME "Preferences with piazzaz.")
set (VERSION "0.9")
set (VERSION_INFO "Release")
#

# Niceties

#

set (ARCHIVE_NAME switchboard-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
    )
add_dependencies(distcheck dist)
add_custom_target (uninstall "${CMAKE_COMMAND}" -P
  "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")
#

# config.h

#

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)
#

# Data

#

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/switchboard.desktop DESTINATION /usr/share/applications)
add_subdirectory(po)
#

# Switchboard

#

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED granite gio-2.0 gee-1.0)
add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.15.1" MINIMUM)
include(ValaPrecompile)
vala_precompile(VALA_C
    Switchboard/switchboard-app.vala
    Switchboard/switchboard-categoryview.vala
    Switchboard/switchboard-resources.vala
PACKAGES
    granite
    gee-1.0
    gio-2.0
CUSTOM_VAPIS
    vapi/config.vapi
    )
add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(switchboard ${VALA_C})
target_link_libraries(switchboard ${DEPS_LIBRARIES})
install(TARGETS switchboard RUNTIME DESTINATION bin)
