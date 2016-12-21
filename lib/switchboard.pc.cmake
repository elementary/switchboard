prefix=@PREFIX@
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@
 
Name: Switchboard
Description: Switchboard headers
Version: @LIB_VERSION@
Libs: -l@LIB_NAME@
Cflags: -I${includedir}/@LIB_NAME@
Requires: glib-2.0 gio-2.0 gee-0.8 gmodule-2.0 gtk+-3.0 gio-unix-2.0

