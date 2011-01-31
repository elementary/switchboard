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

    public AppearancePane () {
        base();
        this.set_name ("Appearance");
    }
}

public static int main (string[] args) {
    // Startup GTK and pass args by reference
    Gtk.init (ref args);
    
    new AppearancePane ();
    
    Gtk.main ();
    return 0;
}

