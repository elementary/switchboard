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

using Gtk;

[DBus (name = "org.elementary.switchboard")]
public interface SwitchboardController : GLib.Object {

    public signal void plug_closed ();
    public abstract int get_socket_wid () throws IOError;

    public abstract void progress_bar_set_visible (bool visibility) throws IOError;
    public abstract void progress_bar_set_fraction (double fraction) throws IOError;
    public abstract void progress_bar_set_text (string text) throws IOError;
    public abstract void progress_bar_pulse () throws IOError;

    public signal void search_box_activated ();
    public abstract void search_box_set_sensitive (bool sensitivity) throws IOError;
    public abstract void search_box_set_text (string text) throws IOError;

}

public abstract class SwitchPlug : Gtk.Plug {
    
    public string plug_name;
    public SwitchboardController switchboard_controller;

    public SwitchPlug (string name) {
        this.plug_name = name;
        GLib.Log.set_default_handler(Log.log_handler);
        try {
            this.switchboard_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.switchboard",
                                                             "/org/elementary/switchboard");
        } catch (IOError e) {
            log ("SettingsPlug", GLib.LogLevelFlags.LEVEL_ERROR, "%s", e.message);
        }
        switchboard_controller.plug_closed.connect(() => exit_plug());
        base.construct ((Gdk.NativeWindow) switchboard_controller.get_socket_wid ());
    }
    

    public void exit_plug () {
    /* Clean up code for saving plug state, etc goes here.
    * method called when the plug is closed */
        stdout.printf("This is the %s plug, signing off gracefully!\n", this.plug_name);
        Gtk.main_quit();
    }
}

