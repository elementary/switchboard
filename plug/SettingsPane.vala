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

public class SettingsPane : Gtk.Plug {
   
    // Fields
    public VBox vbox;
    public HPaned main_pane;
    public string settings_name;

    public SettingsPane (Gdk.NativeWindow wid) {
        stdout.printf("Hey son -- is %i the number you meant?\n", (int) wid);
        base.construct(wid);

//      Init
        this.vbox = new VBox (false, 3);
        this.main_pane = new HPaned ();
        
        this.vbox.pack_start(this.main_pane, true, true);
        this.add (this.vbox);
        this.show_all ();

    }
    
     public void set_name (string inc_name) {

        this.settings_name = inc_name;
    
    }

}

