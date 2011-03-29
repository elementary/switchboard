using ElementaryWidgets;

[DBus (name = "org.elementary.switchplug")]
public class DisplayPlug : SettingsPlug {
    
    public DisplayPlug () {
        base("Monitor");
        var l = new Gtk.Label("foo");
        this.add(l);
    }
}

private new void on_bus_aquired (DBusConnection conn) {
    DisplayPlug display_plug = new DisplayPlug ();
    try {
        conn.register_object ("/org/elementary/switchplug", display_plug);
    } catch (IOError e) {
    }
}

public static int main (string[] args) {
    // Initiate our fancy Log formatting
    GLib.Log.set_default_handler(Log.log_handler);
    
    // Startup GTK and pass args by reference
    Gtk.init (ref args);
    
    // Just create an instance of your plug, everything else is taken care of
    Bus.own_name (BusType.SESSION, "org.elementary.switchplug", /* name to register */
              BusNameOwnerFlags.NONE, /* flags */
              on_bus_aquired, /* callback function on registration succeded */
              () => {}, /* callback on name register succeded */
              () => stderr.printf ("Could not aquire name\n"));
                                                 /* callback on name lost */
    // Run the main loop
    Gtk.main ();
    return 0;
}
