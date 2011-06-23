project (switchboard)
cmake_minimum_required (VERSION 2.8)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/switchboard")
set (GETTEXT_PACKAGE "switchboard")
set (RELEASE_NAME "Preferences with piazzaz.")
set (VERSION "0.8")
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

#
# i18n
#
find_package (Gettext REQUIRED)

add_custom_command (OUTPUT ${CMAKE_SOURCE_DIR}/po/switchboard.pot
        COMMAND xgettext -c --files-from ${CMAKE_SOURCE_DIR}/po/POTFILES.in --keyword=_ -o ${CMAKE_SOURCE_DIR}/po/switchboard.pot --no-wrap --no-location
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )

if (${GETTEXT_FOUND} STREQUAL "TRUE")
        set (HAVE_GETTEXT true)
        file (GLOB _translations ${CMAKE_SOURCE_DIR}/po/*.po)
        GETTEXT_CREATE_TRANSLATIONS (${CMAKE_SOURCE_DIR}/po/${PROJECT_NAME}.pot
                ALL ${_translations})
endif (${GETTEXT_FOUND} STREQUAL "TRUE")

#
# Switchboard
#

set (SWITCHBOARD_DEPS "gobject-2.0;glib-2.0;gtk+-3.0;gee-1.0;")

find_package(PkgConfig)
pkg_check_modules(GLIB REQUIRED "glib-2.0 >= 2.26.0")
pkg_check_modules(GOBJECT REQUIRED "gobject-2.0 >= 2.26.0")
pkg_check_modules(GTK+ REQUIRED "gtk+-3.0 >= 3.0.8")
#pkg_check_modules(GTK+ REQUIRED "gtk+-2.0 >= 2.22.0")
pkg_check_modules(GEE REQUIRED "gee-1.0 >= 0.5.3")
pkg_check_modules(DEPS REQUIRED ${SWITCHBOARD_DEPS})

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})

link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
    Switchboard/Switchboard.vala
    Switchboard/CategoryView.vala
    Switchboard/ElementaryEntry.vala
    Switchboard/AppMenu.vala
PACKAGES
    gtk+-3.0
#    gtk+-2.0
    gee-1.0
CUSTOM_VAPIS
    vapi/config.vapi
    )

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(switchboard ${VALA_C})

install(TARGETS switchboard RUNTIME DESTINATION bin)

