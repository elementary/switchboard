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
        Gee.HashMap<string, string> category_titles = new Gee.HashMap<string, string> ();
        Gtk.IconTheme theme = Gtk.IconTheme.get_default ();

        public signal void plug_selected(Gtk.IconView view, Gtk.ListStore message);

        public CategoryView () {

            category_titles["personal"] = _("Personal");
            category_titles["hardware"] = _("Hardware");
            category_titles["network"] = _("Network and Wireless");
            category_titles["system"] = _("System");
            foreach (var entry in category_titles.entries) {
                var store = new Gtk.ListStore (3, typeof (string), typeof (Gdk.Pixbuf), typeof(string));
                var label = new Gtk.Label ("<big><b>"+entry.value+"</b></big>");
                var category_plugs = new Gtk.IconView.with_model (store);
                category_plugs.set_text_column (0);
                category_plugs.set_pixbuf_column (1);
                category_plugs.selection_changed.connect(() => plug_selected(category_plugs, store));
                var color = Gdk.RGBA ();
                color.parse("#dedede");
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
                category_labels[entry.key] = vbox;
                category_store[entry.key] = store;
                pack_start(vbox);
                vbox.show_all();
                vbox.hide();
            }
        }

        public void add_plug (Gee.HashMap<string, string> plug) {

            Gtk.TreeIter root;
            string plug_down = plug["category"].down();
            if (!category_titles.has_key(plug_down)) {
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
            category_labels[plug_down].show();
        }
    }
}

