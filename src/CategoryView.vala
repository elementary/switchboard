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

        private string? plug_to_open = null;

        public CategoryView (string? plug_to_open = null) {
            this.plug_to_open = plug_to_open;

            setup_category (Switchboard.Plug.Category.PERSONAL, 0);
            setup_category (Switchboard.Plug.Category.HARDWARE, 1);
            setup_category (Switchboard.Plug.Category.NETWORK, 2);
            setup_category (Switchboard.Plug.Category.SYSTEM, 3);
        }

        private void setup_category (Switchboard.Plug.Category category, int i) {
            var category_label = new Gtk.Label (get_category_name (category));
            category_label.get_style_context ().add_class ("category-label");

            category_label.margin_left = 12;
            category_label.margin_right = 8;
            category_label.xalign = (float) 0.02;
            category_label.use_markup = true;

            var category_plugs = setup_icon_view ();

            var bg_css = new Gtk.CssProvider ();
            try {
                bg_css.load_from_data ("*{background-color:@background_color;}", -1);
                category_plugs.get_style_context ().add_provider (bg_css, 20000);
            } catch (Error e) {
                critical (e.message);
            }

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

            category_plugs.focus_out_event.connect ((e)=>{
                category_plugs.unselect_all ();

                return false;
            });

            category_plugs.focus_in_event.connect ((e)=>{
                Gtk.TreePath path;

                if (!category_plugs.get_cursor (out path, null)) {
                    path = new Gtk.TreePath.from_indices (0, -1);
                }
                category_plugs.select_path (path);

                return false;
            });

            category_plugs.keynav_failed.connect ((direction)=> {
                Gtk.IconView new_view = null;
                Gtk.TreePath path = null;
                Gtk.TreeIter iter;
                int d;

                if (direction == Gtk.DirectionType.UP) {
                    new_view = get_prev_icon_view (category);
                    if (new_view != null && category_plugs.get_cursor (out path, null)) {
                        var col = category_plugs.get_item_column (path);

                        Gtk.TreePath sel = null;
                        int dist = 1000;
                        var model = new_view.get_model ();

                        model.get_iter_first (out iter);
                        do {
                            path = model.get_path (iter);
                            var c = new_view.get_item_column (path);
                            d = (c-col).abs ();
                            if (d <= dist) {
                                sel = path;
                                dist = d;
                            }
                        } while (model.iter_next (ref iter));

                        new_view.set_cursor (sel, null, false);
                    }
                } else if (direction == Gtk.DirectionType.DOWN) {
                    new_view = get_next_icon_view (category);
                    if (new_view != null && category_plugs.get_cursor (out path, null)) {
                        var col = category_plugs.get_item_column (path);

                        Gtk.TreePath sel = null;
                        int dist = 1000;
                        var model = new_view.get_model ();

                        model.get_iter_first (out iter);
                        do {
                            path = model.get_path (iter);
                            var c = new_view.get_item_column (path);
                            d = (c-col).abs ();
                            if (d < dist) {
                                sel = path;
                                dist = d;
                            }
                        } while (model.iter_next (ref iter));

                        new_view.set_cursor (sel, null, false);
                    }
                }

                if (new_view != null) {
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


        // in filter mode some icon view will be hidden
        public void grab_focus_first_icon_view () {
            if (personal_iconview.is_visible ())
                personal_iconview.grab_focus ();
            else if (hardware_iconview.is_visible ())
                hardware_iconview.grab_focus ();
            else if (network_iconview.is_visible ())
                network_iconview.grab_focus ();
            else if (system_iconview.is_visible ())
                system_iconview.grab_focus ();
        }

        public void filter_plugs (string filter) {

            var any_found = false;

            if (search_by_category (filter, Switchboard.Plug.Category.PERSONAL))
                any_found = true;
            if (search_by_category (filter, Switchboard.Plug.Category.HARDWARE))
                any_found = true;
            if (search_by_category (filter, Switchboard.Plug.Category.NETWORK))
                any_found = true;
            if (search_by_category (filter, Switchboard.Plug.Category.SYSTEM))
                any_found = true;

            unowned SwitchboardApp app = (SwitchboardApp) GLib.Application.get_default ();
            if (!any_found) {
                app.show_alert (_("No settings found"), _("Try changing your search terms"), Gtk.MessageType.INFO);
            } else {
                app.hide_alert ();
            }
        }
        
        private bool search_by_category (string filter, Plug.Category category) {
            
            Gtk.TreeModelFilter model_filter;
            Gtk.Widget grid;
            
            switch (category) {
                case Switchboard.Plug.Category.PERSONAL:
                    model_filter = (Gtk.TreeModelFilter)personal_iconview.get_model ();
                    grid = personal_grid;
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    model_filter = (Gtk.TreeModelFilter)hardware_iconview.get_model ();
                    grid = hardware_grid;
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    model_filter = (Gtk.TreeModelFilter)network_iconview.get_model ();
                    grid = network_grid;
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    model_filter = (Gtk.TreeModelFilter)system_iconview.get_model ();
                    grid = system_grid;
                    break;
                default:
                    return false;
            }

            var store = model_filter.child_model as Gtk.ListStore;
            int shown = 0;
            store.foreach ((model, path, iter) => {
                string title;

                store.get (iter, Columns.TEXT, out title);

                if (filter.down () in title.down ()) {
                    store.set_value (iter, Columns.VISIBLE, true);
                    shown++;
                } else {
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
            switch (category) {
                case Plug.Category.PERSONAL:
                    return hardware_iconview;
                case Plug.Category.HARDWARE:
                    return network_iconview;
                case Plug.Category.NETWORK:
                    return system_iconview;
            }

            return null;
        }

        private Gtk.IconView? get_prev_icon_view (Switchboard.Plug.Category category) {
            switch (category) {
                case Plug.Category.HARDWARE:
                    return personal_iconview;
                case Plug.Category.NETWORK:
                    return hardware_iconview;
                case Plug.Category.SYSTEM:
                    return network_iconview;
            }

            return null;
        }
    }
}
