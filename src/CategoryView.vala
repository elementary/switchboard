/*
* Copyright (c) 2011-2016 elementary LLC (http://launchpad.net/switchboard)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Avi Romanoff <aviromanoff@gmail.com>
*/

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

        public signal void plug_selected (Switchboard.Plug plug);

        public Switchboard.Category personal_category;
        public Switchboard.Category hardware_category;
        public Switchboard.Category network_category;
        public Switchboard.Category system_category;

        public Gee.ArrayList<SearchEntry?> plug_search_result;

        private string? plug_to_open = null;
        private PlugsSearch plug_search;

        public CategoryView (string? plug_to_open = null) {
            orientation = Gtk.Orientation.VERTICAL;
            plug_to_open = plug_to_open;

            personal_category = new Switchboard.Category (Switchboard.Plug.Category.PERSONAL);
            hardware_category = new Switchboard.Category (Switchboard.Plug.Category.HARDWARE);
            network_category = new Switchboard.Category (Switchboard.Plug.Category.NETWORK);
            system_category = new Switchboard.Category (Switchboard.Plug.Category.SYSTEM);

            add (personal_category);
            add (hardware_category);
            add (network_category);
            add (system_category);

            plug_search = new PlugsSearch ();
            plug_search_result = new Gee.ArrayList<SearchEntry?> ();
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

        private void plug_visibility_changed (Switchboard.Plug plug) {
            if (plug.can_show == true) {
                add_plug (plug);
            }
        }

        public void add_plug (Switchboard.Plug plug) {
            if (plug.can_show == false) {
                return;
            }

            var icon = new Switchboard.CategoryIcon (plug);

            switch (plug.category) {
                case Switchboard.Plug.Category.PERSONAL:
                    personal_category.add (icon);
                    personal_category.show_all ();
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    hardware_category.add (icon);
                    hardware_category.show_all ();
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    network_category.add (icon);
                    network_category.show_all ();
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    system_category.add (icon);
                    system_category.show_all ();
                    break;
                default:
                    return;
            }

            Gtk.TreeIter root;
            Gtk.TreeModelFilter model_filter;

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

        public void grab_focus_first_icon_view () {
            if (personal_category.has_child ()) {
                personal_category.focus_first_child ();
            } else if (hardware_category.has_child ()) {
                hardware_category.focus_first_child ();
            } else if (network_category.has_child ()) {
                network_category.focus_first_child ();
            } else if (system_category.has_child ()) {
                system_category.focus_first_child ();
            }
        }

        public void activate_first_item () {
            if (personal_category.has_child ()) {
                personal_category.activate_first_child ();
            } else if (hardware_category.has_child ()) {
                hardware_category.activate_first_child ();
            } else if (network_category.has_child ()) {
                network_category.activate_first_child ();
            } else if (system_category.has_child ()) {
                system_category.activate_first_child ();
            }
        }

        private bool get_first_visible_path (Gtk.IconView iv, out Gtk.TreePath path) {
            Gtk.TreePath end;

            return (iv.get_visible_range (out path, out end));
        }

        public void filter_plugs (string filter) {

            /*var any_found = false;
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
                app.show_alert (_("No Results for “%s”".printf (filter)), _("Try changing search terms."), "edit-find-symbolic");
            } else {
                app.hide_alert ();
            }*/
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

        public static string? get_category_name (Switchboard.Plug.Category category) {
            switch (category) {
                case Plug.Category.PERSONAL:
                    return _("Personal");
                case Plug.Category.HARDWARE:
                    return _("Hardware");
                case Plug.Category.NETWORK:
                    return _("Network & Wireless");
                case Plug.Category.SYSTEM:
                    return _("Administration");
            }

            return null;
        }
    }
}
