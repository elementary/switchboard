/***
BEGIN LICENSE
Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Lesser General Public License version 3, as 
published by the Free Software Foundation.
 
This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
PURPOSE.  See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along 
with this program.  If not, see <http://www.gnu.org/licenses/>.
END LICENSE
***/

using ElementaryWidgets;

[DBus (name = "org.elementary.SettingsApp")]
interface SettingsAppController : Object {
    // throwing IOError is mandatory for all client interface methods
    public abstract int grab_wid () throws IOError;
    public abstract void identify (string out_string) throws IOError;
}

public class AppearancePane : SettingsPane {

    public AppearancePane (Gdk.NativeWindow in_wid) {
        base(in_wid);
        this.set_name ("Appearance");
        
    }
}

public static int main (string[] args) {
    // Startup GTK and pass args by reference
    Gtk.init (ref args);
    
    int wid = 0;
    try {
        SettingsAppController settings_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.SettingsApp",
                                                         "/org/elementary/settingsapp");
        wid = settings_controller.grab_wid ();
        settings_controller.identify (" - Appearance");

    } catch (IOError e) {
        stderr.printf ("%s\n", e.message);
    }
    stdout.printf ("BLAM! Just like that I figured out that %i was his WID!\n", wid);
    var appearance = new AppearancePane ((Gdk.NativeWindow) wid);
    appearance.destroy.connect (Gtk.main_quit);
    appearance.show_all ();
    Gtk.main ();
    return 0;
}
    

