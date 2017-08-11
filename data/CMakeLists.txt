include (Translations)
configure_file_translation(${CMAKE_SOURCE_DIR}/data/org.pantheon.switchboard.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.switchboard.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation(${CMAKE_SOURCE_DIR}/data/io.elementary.switchboard.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.switchboard.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.switchboard.desktop DESTINATION ${DATADIR}/applications)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.switchboard.appdata.xml DESTINATION ${DATADIR}/metainfo)

