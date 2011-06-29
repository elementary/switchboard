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

    public class CategoryView : Gtk.VBox {
        private Gee.HashMap<string, Gtk.VBox> category_labels = new Gee.HashMap<string, Gtk.VBox>();
        private Gee.HashMap<string, ListStore> category_store = new Gee.HashMap<string, ListStore>();
        private Gtk.IconTheme theme = Gtk.IconTheme.get_default();
        private static Gee.HashMap<string, string> category_titles = new Gee.HashMap<string, string>();

        public signal void plug_selected(IconView view, ListStore message);

        public CategoryView () {
            category_titles["personal"] = "Personal";
            category_titles["hardware"] = "Hardware";
            category_titles["network"] = "Network and Wireless";
            category_titles["system"] = "System";
            foreach (var entry in this.category_titles.entries) {
                var store = new ListStore (3, typeof (string), typeof (Gdk.Pixbuf), typeof(string));
                var label = new Gtk.Label("<big><b>"+entry.value+"</b></big>");
                var category_plugs = new Gtk.IconView.with_model (store);
                category_plugs.set_text_column (0);
                category_plugs.set_pixbuf_column (1);
                category_plugs.selection_changed.connect(() => this.plug_selected(category_plugs, store));
                var color = Gdk.RGBA ();
                color.parse("#dedede");
                category_plugs.override_background_color (Gtk.StateFlags.NORMAL, color);
                label.xalign = (float) 0.02;
                var vbox = new Gtk.VBox(false, 0); // not homogeneous, 0 spacing
                var headbox = new Gtk.HBox(false, 5);
                label.use_markup = true;
                // Always add a Seperator
                var hsep = new Gtk.HSeparator();
                headbox.pack_end(hsep, true, true); // expand, fill, padding´
                headbox.pack_start(label, false, false, 10);
                vbox.pack_start(headbox, false, true, 5);
                vbox.pack_end(category_plugs, true, true);
                this.category_labels[entry.key] = vbox;
                this.category_store[entry.key] = store;
                this.pack_start(vbox);
                vbox.show_all();
                vbox.hide();
            }
        }

        public void add_plug (Gee.HashMap<string, string> plug) {
            Gtk.TreeIter root;
            if (!category_titles.has_key(plug["category"].down())) {
                stdout.printf("Keyfile \"%s\" contains an invalid category: \"%s\", and will not be added.\n", plug["title"], plug["category"].down());
            }
            this.category_store[plug["category"].down()].append (out root);
            try {
                var icon_pixbuf = this.theme.load_icon (plug["icon"], 48, Gtk.IconLookupFlags.GENERIC_FALLBACK);
                this.category_store[plug["category"].down()].set (root, 1, icon_pixbuf, -1);
            } catch {
                GLib.log(SwitchBoard.ERRDOMAIN, LogLevelFlags.LEVEL_DEBUG,
                "Unable to load plug %s's icon: %s", plug["title"], plug["icon"]);
            }
            this.category_store[plug["category"].down()].set (root, 0, plug["title"], -1);
            this.category_store[plug["category"].down()].set (root, 2, plug["exec"], -1);
            this.category_labels[plug["category"].down()].show();
        }
    }
}

