/***
BEGIN LICENSE
Copyright (C) 2011-2012 Avi Romanoff <aviromanoff@gmail.com>
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

namespace Switchboard {

    public class CategoryView : Gtk.VBox {

        Gee.HashMap<string, Gtk.VBox> category_labels = new Gee.HashMap<string, Gtk.VBox> ();
        public Gee.HashMap<string, Gtk.ListStore> category_store = new Gee.HashMap<string, Gtk.ListStore> ();
        public Gee.HashMap<string, Gtk.IconView> category_views = new Gee.HashMap<string, Gtk.IconView> ();
        Gtk.IconTheme theme = Gtk.IconTheme.get_default ();

        public signal void plug_selected (string title, string executable);
        string [] category_ids = { "personal", "hardware", "network", "system" };
        string [] category_names = { N_("Personal"), N_("Hardware"), N_("Network and Wireless"), N_("System") };

        public CategoryView () {
            for (int i = 0; i < category_ids.length; i++) {
                var store = new Gtk.ListStore (4, typeof (string), typeof (Gdk.Pixbuf), 
                    typeof(string), typeof(bool));
                
                var label = new Gtk.Label ("<big><b>" + _(category_names[i]) + "</b></big>");
                label.margin_left = 12;
                var filtered = new Gtk.TreeModelFilter(store, null);
                filtered.set_visible_column(3);
                filtered.refilter();
                
                var category_plugs = new Gtk.IconView.with_model (filtered);
                // category_plugs.
                category_plugs.set_text_column (0);
                category_plugs.set_pixbuf_column (1);
                category_plugs.selection_changed.connect(() => on_selection_changed(category_plugs, filtered));
                
                (category_plugs.get_cells ().nth_data (0) as Gtk.CellRendererText).wrap_mode = Pango.WrapMode.WORD;
                // (category_plugs.get_cells ().nth_data (0) as Gtk.CellRendererText).ellipsize = 
                    // Pango.EllipsizeMode.END;
                
                var bg_css = new Gtk.CssProvider ();
                try {
                    bg_css.load_from_data ("*{background-color:@background_color;}", -1);
                } catch (Error e) { warning (e.message); }
                category_plugs.get_style_context ().add_provider (bg_css, 20000);
                label.xalign = (float) 0.02;
                
                var vbox = new Gtk.VBox (false, 0); // not homogeneous, 0 spacing
                var headbox = new Gtk.HBox (false, 0);
                label.use_markup = true;
                
                // Always add a Seperator
                var hsep = new Gtk.HSeparator ();
                headbox.pack_end(hsep, true, true); // expand, fill, padding´
                headbox.pack_start(label, false, false, 0);
                
                vbox.pack_start(headbox, false, true, 0);
                vbox.pack_end(category_plugs, true, true);
                
                category_labels[category_ids[i]] = vbox;
                category_store[category_ids[i]] = store;
                category_views[category_ids[i]] = category_plugs;
                
                pack_start(vbox);
            }
        }

        public void add_plug (Gee.HashMap<string, string> plug) {

            Gtk.TreeIter root;
            string plug_down = plug["category"].down();
            
            if (!(plug_down in category_ids)) {
                warning (_("Keyfile \"%s\" contains an invalid category: \"%s\", and will not be added"), 
                    plug["title"], plug["category"]);
                return;
            }
            
            Gdk.Pixbuf icon_pixbuf = null;
            try {
                icon_pixbuf = theme.load_icon (plug["icon"], 32, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            } catch {
                warning(_("Unable to load plug %s's icon: %s"), plug["title"], plug["icon"]);
                return; // FIXME: if we get no icon, we probably dont want that one..
            }
            category_store[plug_down].append(out root);
            
            category_store[plug_down].set(root, 0, plug["title"], 1, icon_pixbuf, 2, plug["exec"], 
                3, false);
            category_labels[plug_down].show_all();
        }

        public void filter_plugs (string filter, SwitchboardApp switchboard) {
            
            var any_found = false;
            foreach (string category in category_ids) {

                var store = category_store[category];
                var container = category_labels[category];

                int shown = 0;

                store.foreach((model, path, iter) => {
                    string title;

                    store.get (iter, 0, out title);

                    if (filter.down () in title.down ()) {
                        store.set_value (iter, 3, true);
                        shown ++;
                    } else {
                        store.set_value (iter, 3, false);
                    }

                    return false;
                });
                
                if (shown == 0) {
                    container.hide ();
                } else {
                    any_found = true;
                    container.show ();
                }
            }
            if (!any_found) {
                switchboard.show_alert("No plugs found", "Try changing your search terms", Gtk.MessageType.INFO);
            } else {
                switchboard.hide_alert();
            }
        }

        private void on_selection_changed (Gtk.IconView view, Gtk.TreeModelFilter store) {
            
            GLib.Value title;
            GLib.Value executable;
            Gtk.TreeIter selected_plug;
            
            var selected = view.get_selected_items ();
            var item = selected.nth_data(0);

            if (item == null)
                return;

            store.get_iter (out selected_plug, item);
            store.get_value (selected_plug, 0, out title);
            store.get_value (selected_plug, 2, out executable);

            plug_selected (title.get_string(), executable.get_string());

            view.unselect_path (item);
        }
    }
}

