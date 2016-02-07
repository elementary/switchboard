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

    public class CategoryView : Gtk.Grid {

        public enum Columns {
            ICON,
            TEXT,
            DESCRIPTION,
            VISIBLE,
            PLUG,
            N_COLUMNS
        }

        const int ITEM_WIDTH = 96;

        public signal void plug_selected (Switchboard.Plug plug);

        Gtk.IconTheme theme = Gtk.IconTheme.get_default ();
        Gtk.Grid personal_grid;
        Gtk.Grid hardware_grid;
        Gtk.Grid network_grid;
        Gtk.Grid system_grid;

        public Gtk.IconView personal_iconview;
        public Gtk.IconView hardware_iconview;
        public Gtk.IconView network_iconview;
        public Gtk.IconView system_iconview;
        public Gee.ArrayList<SearchEntry?> plug_search_result;

        private string? plug_to_open = null;
        private PlugsSearch plug_search;

        public CategoryView (string? plug_to_open = null) {
            this.plug_to_open = plug_to_open;
            setup_category (Switchboard.Plug.Category.PERSONAL, 0);
            setup_category (Switchboard.Plug.Category.HARDWARE, 1);
            setup_category (Switchboard.Plug.Category.NETWORK, 2);
            setup_category (Switchboard.Plug.Category.SYSTEM, 3);
            plug_search = new PlugsSearch ();
            plug_search_result = new Gee.ArrayList<SearchEntry?> ();
        }

        private void setup_category (Switchboard.Plug.Category category, int i) {
            var category_label = new Gtk.Label (get_category_name (category));
            category_label.get_style_context ().add_class ("category-label");

            category_label.margin_left = 12;
            category_label.margin_right = 8;
            ((Gtk.Misc) category_label).xalign = 0.02f;
            category_label.use_markup = true;

            var category_plugs = setup_icon_view ();
            category_plugs.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

            var grid = new Gtk.Grid ();

            // Always add a Seperator
            var h_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            h_separator.set_hexpand (true);
            h_separator.margin_right = 12;
            grid.attach (category_label, 0, 0, 1, 1);
            grid.attach (h_separator, 1, 0, 1, 1);

            grid.attach (category_plugs, 0, 1, 2, 1);
            switch (category) {
                case Switchboard.Plug.Category.PERSONAL:
                    personal_iconview = category_plugs;
                    personal_grid = grid;
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    hardware_iconview = category_plugs;
                    hardware_grid = grid;
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    network_iconview = category_plugs;
                    network_grid = grid;
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    system_iconview = category_plugs;
                    system_grid = grid;
                    break;
            }

            category_plugs.focus_out_event.connect ((e) => {
                category_plugs.unselect_all ();

                return false;
            });

            category_plugs.focus_in_event.connect ((e) => {
                Gtk.TreePath path;

                if (!category_plugs.get_cursor (out path, null)) {
                    path = new Gtk.TreePath.from_indices (0, -1);
                }
                category_plugs.select_path (path);

                return false;
            });

            category_plugs.keynav_failed.connect ((direction) => {
                Gtk.IconView new_view = null;
                Gtk.TreePath path = null;
                Gtk.TreePath selected_path = null;
                int smallest_distance = 1000;
                Gtk.TreeIter iter;
                int distance;

                if (direction == Gtk.DirectionType.UP) {
                    new_view = get_prev_icon_view (category);
                    if (new_view != null && category_plugs.get_cursor (out path, null)) {
                        var current_column = category_plugs.get_item_column (path);
                        var model = new_view.get_model ();

                        model.get_iter_first (out iter);
                        do {
                            path = model.get_path (iter);
                            var next_column = new_view.get_item_column (path);
                            distance = (next_column - current_column).abs ();
                            if (distance <= smallest_distance) {
                                selected_path = path;
                                smallest_distance = distance;
                            }
                        } while (model.iter_next (ref iter));
                    }
                } else if (direction == Gtk.DirectionType.DOWN) {
                    new_view = get_next_icon_view (category);
                    if (new_view != null && category_plugs.get_cursor (out path, null)) {
                        var current_column = category_plugs.get_item_column (path);
                        var model = new_view.get_model ();

                        model.get_iter_first (out iter);
                        do {
                            path = model.get_path (iter);
                            var next_column = new_view.get_item_column (path);
                            distance = (next_column - current_column).abs ();
                            if (distance < smallest_distance) {
                                selected_path = path;
                                smallest_distance = distance;
                            }
                        } while (model.iter_next (ref iter));
                    }
                }

                if (new_view != null) {
                    new_view.set_cursor (selected_path, null, false);
                    new_view.grab_focus ();
                    return true;
                }

                return false;
            });

            attach (grid, 0, i, 1, 1);
        }

        public async void load_default_plugs () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();
            plugsmanager.plug_added.connect ((plug) => {
                plug.visibility_changed.connect (() => plug_visibility_changed (plug));
                add_plug (plug);
            });

            Idle.add (() => {
                foreach (var plug in plugsmanager.get_plugs ()) {
                    plug.visibility_changed.connect (() => plug_visibility_changed (plug));
                    if (plug.can_show == true) {
                        add_plug (plug);
                    }
                }

                return false;
            });
        }

        private Gtk.IconView setup_icon_view () {
            var store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (Gdk.Pixbuf), typeof (string),
                typeof(string), typeof(bool), typeof(Switchboard.Plug));
            store.set_sort_column_id (1, Gtk.SortType.ASCENDING);
            store.set_sort_column_id (1, Gtk.SortType.ASCENDING);

            var filtered = new Gtk.TreeModelFilter (store, null);
            filtered.set_visible_column (3);
            filtered.refilter ();

            var category_plugs = new Gtk.IconView.with_model (filtered);
            category_plugs.set_item_width (ITEM_WIDTH);
            category_plugs.set_text_column (Columns.TEXT);
            category_plugs.set_pixbuf_column (Columns.ICON);
            category_plugs.set_tooltip_column (Columns.DESCRIPTION);
            category_plugs.set_hexpand (true);
            category_plugs.set_selection_mode (Gtk.SelectionMode.SINGLE);
            category_plugs.set_activate_on_single_click (true);

            category_plugs.item_activated.connect (on_item_activated);
            var cellrenderer = (Gtk.CellRendererText)category_plugs.get_cells ().nth_data (0);
            cellrenderer.wrap_mode = Pango.WrapMode.WORD;
            cellrenderer.ellipsize_set = true;

            return category_plugs;
        }

        private void plug_visibility_changed (Switchboard.Plug plug) {
            if (plug.can_show == true) {
                add_plug (plug);
            }
        }

        public void add_plug (Switchboard.Plug plug) {
            if (plug.can_show == false)
                return;
            Gtk.TreeIter root;
            Gtk.TreeModelFilter model_filter;

            switch (plug.category) {
                case Switchboard.Plug.Category.PERSONAL:
                    model_filter = (Gtk.TreeModelFilter)personal_iconview.get_model ();
                    personal_grid.show_all ();
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    model_filter = (Gtk.TreeModelFilter)hardware_iconview.get_model ();
                    hardware_grid.show_all ();
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    model_filter = (Gtk.TreeModelFilter)network_iconview.get_model ();
                    network_grid.show_all ();
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    model_filter = (Gtk.TreeModelFilter)system_iconview.get_model ();
                    system_grid.show_all ();
                    break;
                default:
                    return;
            }

            var store = model_filter.child_model as Gtk.ListStore;
            Gdk.Pixbuf icon_pixbuf = null;
            try {
                // FIXME: if we get no icon, we probably dont want that one…
                icon_pixbuf = theme.load_icon (plug.icon, 32, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            } catch {
                critical ("Unable to load plug %s's icon: %s", plug.display_name, plug.icon);
                return;
            }

            store.append (out root);
            store.set (root, Columns.ICON, icon_pixbuf, Columns.TEXT, plug.display_name,
                Columns.DESCRIPTION, plug.description, Columns.VISIBLE, true, Columns.PLUG, plug);
            unowned SwitchboardApp app = (SwitchboardApp) GLib.Application.get_default ();
            app.search_box.sensitive = true;
            filter_plugs (app.search_box.get_text ());
#if HAVE_UNITY
            app.update_libunity_quicklist ();
#endif
            if (plug_to_open != null && plug_to_open != "") {
                if (plug_to_open.has_suffix (plug.code_name)) {
                    app.load_plug (plug);
                    plug_to_open = "";
                }
            }
        }


        // focus to first visible item
        public void grab_focus_first_icon_view () {
                Gtk.TreePath first_path = null;

                if (get_first_visible_path (personal_iconview, out first_path)) {
                    personal_iconview.grab_focus ();
                } else if (get_first_visible_path (hardware_iconview, out first_path)) {
                    hardware_iconview.grab_focus ();
                } else if (get_first_visible_path (network_iconview, out first_path)) {
                    network_iconview.grab_focus ();
                } else if (get_first_visible_path (system_iconview, out first_path)) {
                    system_iconview.grab_focus ();
                }
        }

        // activate first visible item
        public void activate_first_item () {
                Gtk.TreePath first_path = null;

                if (get_first_visible_path (personal_iconview, out first_path)) {
                    personal_iconview.item_activated (first_path);
                } else if (get_first_visible_path (hardware_iconview, out first_path)){
                    hardware_iconview.item_activated (first_path);
                } else if (get_first_visible_path (network_iconview, out first_path)){
                    network_iconview.item_activated (first_path);
                } else if (get_first_visible_path (system_iconview, out first_path)){
                    system_iconview.item_activated (first_path);
                }
        }

        private bool get_first_visible_path (Gtk.IconView iv, out Gtk.TreePath path) {
            Gtk.TreePath end;

            return (iv.get_visible_range (out path, out end));
        }

        public void filter_plugs (string filter) {

            var any_found = false;
            var model_filter = (Gtk.TreeModelFilter) personal_iconview.get_model ();
            if (search_by_category (filter, model_filter, personal_grid)) {
                any_found = true;
            }

            model_filter = (Gtk.TreeModelFilter) hardware_iconview.get_model ();
            if (search_by_category (filter, model_filter, hardware_grid)) {
                any_found = true;
            }

            model_filter = (Gtk.TreeModelFilter) network_iconview.get_model ();
            if (search_by_category (filter, model_filter, network_grid)) {
                any_found = true;
            }

            model_filter = (Gtk.TreeModelFilter) system_iconview.get_model ();
            if (search_by_category (filter, model_filter, system_grid)) {
                any_found = true;
            }

            unowned SwitchboardApp app = (SwitchboardApp) GLib.Application.get_default ();
            if (!any_found) {
                app.show_alert (_("No settings found"), _("Try changing your search terms"), Gtk.MessageType.INFO);
            } else {
                app.hide_alert ();
            }
        }

        private void deep_search (string filter) {
            if (plug_search.ready) {
                plug_search_result.clear ();
                foreach (var tmp in plug_search.search_entries) {
                    if (tmp.ui_elements.down ().contains (filter.down ())) {
                        plug_search_result.add (tmp);
                    }
                }
            }
        }

        private bool search_by_category (string filter, Gtk.TreeModelFilter model_filter, Gtk.Widget grid) {

            deep_search (filter);
            var store = model_filter.child_model as Gtk.ListStore;
            int shown = 0;
            store.foreach ((model, path, iter) => {
                string title;

                store.get (iter, Columns.TEXT, out title);
                bool show_element = false;
                foreach (var tmp in plug_search_result) {
                    if (tmp.plug_name.down () in title.down ()) {
                        store.set_value (iter, Columns.VISIBLE, true);
                        shown++;
                        show_element = true;
                    }
                }

                if (filter.down () in title.down ()) {
                    store.set_value (iter, Columns.VISIBLE, true);
                    shown++;
                } else if (!show_element) {
                    store.set_value (iter, Columns.VISIBLE, false);
                }

                return false;
            });

            if (shown == 0) {
                grid.hide ();
                return false;
            } else {
                grid.show_all ();
                return true;
            }
        }

        public void recalculate_columns () {
            int columns = personal_iconview.get_columns ();
            columns = int.max (columns, hardware_iconview.get_columns ());
            columns = int.max (columns, network_iconview.get_columns ());
            columns = int.max (columns, system_iconview.get_columns ());
            personal_iconview.set_columns (columns);
            hardware_iconview.set_columns (columns);
            network_iconview.set_columns (columns);
            system_iconview.set_columns (columns);
        }

        private void on_item_activated (Gtk.IconView view, Gtk.TreePath path) {
            GLib.Value plug;
            Gtk.TreeIter selected_plug;
            var store = view.get_model ();

            store.get_iter (out selected_plug, path);
            store.get_value (selected_plug, Columns.PLUG, out plug);

            plug_selected ((Switchboard.Plug) plug.get_object ());

            view.unselect_path (path);
        }

        public static string? get_category_name (Switchboard.Plug.Category category) {
            switch (category) {
                case Plug.Category.PERSONAL:
                    return _("Personal");
                case Plug.Category.HARDWARE:
                    return _("Hardware");
                case Plug.Category.NETWORK:
                    return _("Network and Wireless");
                case Plug.Category.SYSTEM:
                    return _("Administration");
            }

            return null;
        }

        private Gtk.IconView? get_next_icon_view (Switchboard.Plug.Category category) {
            if (category == Plug.Category.PERSONAL) {
                if (hardware_iconview.is_visible ())
                    return hardware_iconview;
                else
                    category = Plug.Category.HARDWARE;
            }

            if (category == Plug.Category.HARDWARE) {
                if (network_iconview.is_visible ())
                    return network_iconview;
                else
                    category = Plug.Category.NETWORK;
            }

            if (category == Plug.Category.NETWORK) {
                if (system_iconview.is_visible ())
                    return system_iconview;
                else
                    category = Plug.Category.SYSTEM;
            }

            return null;
        }

        private Gtk.IconView? get_prev_icon_view (Switchboard.Plug.Category category) {
            if (category == Plug.Category.SYSTEM) {
                if (network_iconview.is_visible ())
                    return network_iconview;
                else
                    category = Plug.Category.NETWORK;
            }

            if (category == Plug.Category.NETWORK) {
                if (hardware_iconview.is_visible ())
                    return hardware_iconview;
                else
                    category = Plug.Category.HARDWARE;
            }

            if (category == Plug.Category.HARDWARE) {
                if (personal_iconview.is_visible ())
                    return personal_iconview;
                else
                    category = Plug.Category.SYSTEM;
            }

            return null;
        }
    }
}
