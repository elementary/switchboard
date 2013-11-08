macro(add_target_gir TARGET_NAME GIR_NAME HEADER C_FILES CFLAGS LIB_VERSION)
    set(PACKAGES "")
    foreach(PKG ${ARGN})
        set(PACKAGES ${PACKAGES} --include=${PKG})
    endforeach()
    install(CODE "set(ENV{LD_LIBRARY_PATH} \"${CMAKE_CURRENT_BINARY_DIR}:\$ENV{LD_LIBRARY_PATH}\")
    execute_process(COMMAND g-ir-scanner --pkg=${LIB_PACKAGE} -n ${GIR_NAME}
            --library ${CMAKE_PROJECT_NAME} ${PACKAGES}
            --warn-all
            --header-only
            -o ${CMAKE_CURRENT_BINARY_DIR}/${GIR_NAME}-${LIB_VERSION}.gir
            -L${CMAKE_CURRENT_BINARY_DIR}
            --nsversion=${LIB_VERSION} ${CMAKE_CURRENT_BINARY_DIR}/${HEADER})")
    install(CODE "execute_process(COMMAND g-ir-compiler ${CMAKE_CURRENT_BINARY_DIR}/${GIR_NAME}-${LIB_VERSION}.gir -o ${CMAKE_CURRENT_BINARY_DIR}/${GIR_NAME}-${LIB_VERSION}.typelib)")
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${GIR_NAME}-${LIB_VERSION}.gir DESTINATION share/gir-1.0/)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${GIR_NAME}-${LIB_VERSION}.typelib DESTINATION lib/girepository-1.0/)
endmacro()
