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

[DBus (name = "org.elementary.switchplug")]
public class AppearancePlug : SwitchPlug {
    
    private Gtk.Label test_text;
    
    public AppearancePlug () {
        base("Appearance");
        test_text = new Gtk.Label.with_mnemonic ("Appearance junk goes here!");
        this.add(test_text);
        this.show_all();
    }
}

public static int main (string[] args) {
    // Initiate our fancy Log formatting
    GLib.Log.set_default_handler(Log.log_handler);
    
    // Startup GTK and pass args by reference
    Gtk.init (ref args);

    AppearancePlug appearance_plug = new AppearancePlug ();
    Gtk.main ();
    return 0;
}

