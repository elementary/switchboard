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

namespace Switchboard {

    public class CategoryView : Gtk.VBox {

        Gee.HashMap<string, Gtk.VBox> category_labels = new Gee.HashMap<string, Gtk.VBox> ();
        Gee.HashMap<string, Gtk.ListStore> category_store = new Gee.HashMap<string, Gtk.ListStore> ();
        Gee.HashMap<string, Gtk.IconView> category_views = new Gee.HashMap<string, Gtk.IconView> ();
        Gtk.IconTheme theme = Gtk.IconTheme.get_default ();

        public signal void plug_selected(Gtk.IconView view, Gtk.ListStore message);
        string [] category_ids = { "personal", "hardware", "network", "system" };
        string [] category_names = { N_("Personal"), N_("Hardware"), N_("Network and Wireless"), N_("System") };

        public CategoryView () {
            for (int i = 0; i < category_ids.length; i++) {
                var store = new Gtk.ListStore (4, typeof (string), typeof (Gdk.Pixbuf), typeof(string), typeof(bool));
                var label = new Gtk.Label ("<big><b>" + _(category_names[i]) + "</b></big>");
                var filtered = new Gtk.TreeModelFilter(store, null);
                filtered.set_visible_column(3);
                filtered.refilter();
                var category_plugs = new Gtk.IconView.with_model (filtered);
                category_plugs.set_text_column (0);
                category_plugs.set_pixbuf_column (1);
                category_plugs.selection_changed.connect(() => plug_selected(category_plugs, store));
                var color = get_style_context().get_background_color(Gtk.StateFlags.NORMAL);
                category_plugs.override_background_color (Gtk.StateFlags.NORMAL, color);
                label.xalign = (float) 0.02;
                var vbox = new Gtk.VBox (false, 0); // not homogeneous, 0 spacing
                var headbox = new Gtk.HBox (false, 5);
                label.use_markup = true;
                // Always add a Seperator
                var hsep = new Gtk.HSeparator ();
                headbox.pack_end(hsep, true, true); // expand, fill, padding´
                headbox.pack_start(label, false, false, 10);
                vbox.pack_start(headbox, false, true, 5);
                vbox.pack_end(category_plugs, true, true);
                category_labels[category_ids[i]] = vbox;
                category_store[category_ids[i]] = store;
                category_views[category_ids[i]] = category_plugs;
                pack_start(vbox);
                vbox.show_all();
                vbox.hide();
            }
        }

        public void add_plug (Gee.HashMap<string, string> plug) {

            Gtk.TreeIter root;
            string plug_down = plug["category"].down();
            if (!(plug_down in category_ids)) {
                warning(_("Keyfile \"%s\" contains an invalid category: \"%s\", and will not be added"), plug["title"], plug["category"]);
            }
            category_store[plug_down].append(out root);
            try {
                var icon_pixbuf = theme.load_icon (plug["icon"], 48, Gtk.IconLookupFlags.GENERIC_FALLBACK);
                category_store[plug_down].set(root, 1, icon_pixbuf);
            } catch {
                warning(_("Unable to load plug %'s icon: %s"), plug["title"], plug["icon"]);
            }
            category_store[plug_down].set(root, 0, plug["title"]);
            category_store[plug_down].set(root, 2, plug["exec"]);
            category_store[plug_down].set(root, 3, true);
            category_labels[plug_down].show();
        }

        public void filter_plugs (string filter) {
            
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
                    } else store.set_value (iter, 3, false);

                    return false;
                });
                
                if (shown == 0)
                    container.hide ();
                else
                    container.show ();
            }
        }
    }
}

