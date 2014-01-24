prefix=@PREFIX@
exec_prefix=@DOLLAR@{prefix}
libdir=@DOLLAR@{prefix}/lib
includedir=@DOLLAR@{prefix}/include/
 
Name: Switchboard
Description: Switchboard headers  
Version: 2.0  
Libs: -lswitchboard-2.0
Cflags: -I@DOLLAR@{includedir}/switchboard-2.0
Requires: glib-2.0 gio-2.0 gee-0.8 gmodule-2.0 gtk+-3.0 gio-unix-2.0

