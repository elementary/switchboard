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
    public signal void go_back();
    public signal void go_forward();
    
    public abstract int get_socket_wid () throws IOError;
    public abstract void update_window_title (string new_title) throws IOError;
}

public class SettingsPane : Gtk.Plug {
    /* Signals */
    public signal bool go_back();
    public signal bool go_forward();
    
    /** Fields **/
    public VBox vbox;
    public HPaned main_pane;
    public string settings_name;
    public SettingsAppController settings_controller;
    
    private string _window_title;
    private string _pane_name;
    
    /** Properties **/
    public string title {
        get { return _window_title; }
        set {
            _window_title = value;
            this.set_window_title(value);
        }
    }
    
    public SettingsPane (string pane_name) {
        int wid = 0;
        try {
            this.settings_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.switchboard",
                                                             "/org/elementary/switchboard");
            wid = settings_controller.get_socket_wid ();
            settings_controller.go_back.connect(this.go_back_handler);
            settings_controller.go_forward.connect(this.go_forward_handler);
        } catch (IOError e) {
            GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_ERROR, "%s", e.message);
        }
        GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_DEBUG, "SwitchBoards WID is %i!", wid);
        base.construct((Gdk.NativeWindow) wid);
        
        /* Init */
        _pane_name = pane_name;
        title = pane_name;
        
        /* Exit App if the Plug gets destroyed */
        this.destroy.connect (Gtk.main_quit);
    }
    
    private void go_back_handler() {
        GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_DEBUG, "Recieved Back signal");
        if(!this.go_back()) {
            Gtk.main_quit();
            GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_DEBUG, "Quitting");
        }
    }
    
    private void go_forward_handler() {
        GLib.log("SettingsPane", GLib.LogLevelFlags.LEVEL_DEBUG, "Recieved Forward signal");
        this.go_forward();
    }
    
    private void set_window_title (string new_title) {
        try {
            settings_controller.update_window_title(new_title);
        } catch (IOError e) {
            GLib.log(_pane_name, LogLevelFlags.LEVEL_CRITICAL, 
                    "Failed to set parents Title to %s!", new_title);
        }
    }
}
