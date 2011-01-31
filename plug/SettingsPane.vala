/***
BEGIN LICENSE
Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Lesser General Public License version 2.1, as published 
by the Free Software Foundation.
 
This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
PURPOSE.  See the GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License along 
with this program.  If not, see <http://www.gnu.org/licenses/>.
END LICENSE
***/

using Gtk;

[DBus (name = "org.elementary.SettingsApp")]
public interface SettingsAppController : GLib.Object {
    // throwing IOError is mandatory for all client interface methods
    public abstract int grab_wid () throws IOError;
    public abstract void identify (string out_string) throws IOError;
}

public class SettingsPane : Gtk.Plug {
   
    // Fields
    public VBox vbox;
    public HPaned main_pane;
    public string settings_name;
    public SettingsAppController settings_controller;

    public SettingsPane (string pane_name) {
        int wid = 0;
        try {
            this.settings_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.SettingsApp",
                                                             "/org/elementary/settingsapp");
            wid = settings_controller.grab_wid ();
        } catch (IOError e) {
            stderr.printf ("%s\n", e.message);
        }
        GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_DEBUG, "SwitchBoards WID is %i!", wid);
        base.construct((Gdk.NativeWindow) wid);
        
//      Init
        this.vbox = new VBox (false, 3);
        this.main_pane = new HPaned ();
        
        this.vbox.pack_start(this.main_pane, true, true);
        this.add (this.vbox);
        this.show_all ();
        // Exit App if the Plug gets destroyed
        this.destroy.connect (Gtk.main_quit);
    }
    
     public void set_name (string inc_name) {
        this.settings_name = inc_name;
        try {
            settings_controller.identify (inc_name);
        } catch (IOError e) {
            GLib.log(inc_name, LogLevelFlags.LEVEL_CRITICAL, "Failed to set parents Title!");
        }
    }

}

