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

namespace SwitchBoard {

    public class Categories : Gtk.VBox {

        private string[] category_titles = {};

        public Categories (string[] titles) {
            this.category_titles = titles;
            foreach (string title in this.category_titles) {
                var label = new Gtk.Label("<big><b>"+title+"</b></big>");
                var store = new ListStore (3, typeof (string), typeof (Gdk.Pixbuf), typeof(string));
                var category_plugs = new Gtk.IconView.with_model (store);
                category_plugs.set_text_column (0);
                category_plugs.set_pixbuf_column (1);
                var color = Gdk.Color ();
                Gdk.Color.parse ("#dedede", out color);
                category_plugs.modify_base (Gtk.StateType.NORMAL, color);
                label.xalign = (float) 0.02;
                label.ypad = 5;
                var vbox = new Gtk.VBox(false, 0); // not homogeneous, 0 spacing
                label.use_markup = true;
                if (title != this.category_titles[0]) {
                    var hsep = new Gtk.HSeparator();
                    vbox.pack_start(hsep, false, false); // expand, fill, padding
                }
                vbox.pack_start(label, false, true);
                vbox.pack_end(category_plugs, true, true);
                this.pack_start(vbox);
            }
        }
        
    }

}
