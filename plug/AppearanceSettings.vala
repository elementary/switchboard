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

public class AppearancePane : SettingsPane {
    
    private Gtk.Label test_text;
    
    public AppearancePane () {
        base("Appeareance");
        //title = "Appearance - test";
        test_text = new Gtk.Label.with_mnemonic ("This is a very awesome Appereance view");
        this.add(test_text);
        this.show_all();
        //Connect to Action signals
        this.go_back.connect(this.back_signal);
        this.go_forward.connect(this.forward_signal);
    }
    
    //Signal emmited when the back button in SwitchBoard is pressed
    public bool back_signal() {
        //Returning true means the signal got handled, returning false will 
        //exit the pane and go back to the Icon View
        return true;
    }
    
    //Signal emmited when the back button in SwitchBoard is pressed
    public bool forward_signal() {
        //Returning true means the signal got handled, returning false will 
        //exit the pane and go back to the Icon View
        return true;
    }
}

public static int main (string[] args) {
    // Initiate our fancy Log formatting
    GLib.Log.set_default_handler(Log.log_handler);
    
    // Startup GTK and pass args by reference
    Gtk.init (ref args);
    
    // Just create an instance of your pane, everything else is taken care of
    new AppearancePane ();
    
    // Run the main loop
    Gtk.main ();
    return 0;
}

