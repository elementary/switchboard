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

[DBus (name = "org.elementary.switchboard")]
public interface SettingsAppController : GLib.Object {

    public abstract int get_socket_wid () throws IOError;
}

public class SettingsPlug : Gtk.Plug {
    
    /** Fields **/
    public VBox vbox;
    public HPaned main_pane;
    public string settings_name;
    public SettingsAppController settings_controller;
    
    private string _plug_name;
    
    
    public SettingsPlug (string plug_name) {
        int wid = 0;
        try {
            this.settings_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.switchboard",
                                                             "/org/elementary/switchboard");
            wid = settings_controller.get_socket_wid ();
        } catch (IOError e) {
            GLib.log ("SettingsPlug", GLib.LogLevelFlags.LEVEL_ERROR, "%s", e.message);
        }
        GLib.log ("SettingsPlug", GLib.LogLevelFlags.LEVEL_DEBUG, "SwitchBoards WID is %i!", wid);
        base.construct ((Gdk.NativeWindow) wid);
        
        /* Init */
        _plug_name = plug_name;
        
        /* Exit App if the Plug gets destroyed */
        this.destroy.connect (Gtk.main_quit);
    }
    

}
