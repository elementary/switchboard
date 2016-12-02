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
        public signal void plug_selected (Switchboard.Plug plug);

        public PlugsSearch plug_search { get; construct; }
        public Gee.ArrayList<SearchEntry?> plug_search_result { get; construct; }
        public Switchboard.Category personal_category { get; construct; }
        public Switchboard.Category hardware_category { get; construct; }
        public Switchboard.Category network_category { get; construct; }
        public Switchboard.Category system_category { get; construct; }

        public string? plug_to_open { get; construct set; default = null; }

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            
            personal_category = new Switchboard.Category (Switchboard.Plug.Category.PERSONAL);
            hardware_category = new Switchboard.Category (Switchboard.Plug.Category.HARDWARE);
            network_category = new Switchboard.Category (Switchboard.Plug.Category.NETWORK);
            system_category = new Switchboard.Category (Switchboard.Plug.Category.SYSTEM);

            plug_search = new PlugsSearch ();
            plug_search_result = new Gee.ArrayList<SearchEntry?> ();

            add (personal_category);
            add (hardware_category);
            add (network_category);
            add (system_category);
        }

        public CategoryView (string? plug = null) {
            Object (plug_to_open: plug);
        }

        public async void load_default_plugs () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();
            plugsmanager.plug_added.connect ((plug) => {
                plug.visibility_changed.connect (() => add_plug (plug));
                add_plug (plug);
            });

            Idle.add (() => {
                foreach (var plug in plugsmanager.get_plugs ()) {
                    plug.visibility_changed.connect (() => add_plug (plug));
                    add_plug (plug);
                }

                return false;
            });
        }

        public void add_plug (Switchboard.Plug plug) {
            if (!plug.can_show) {
                return;
            }

            var icon = new Switchboard.CategoryIcon (plug);

            switch (plug.category) {
                case Switchboard.Plug.Category.PERSONAL:
                    personal_category.add (icon);
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    hardware_category.add (icon);
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    network_category.add (icon);
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    system_category.add (icon);
                    break;
                default:
                    return;
            }

            unowned SwitchboardApp app = SwitchboardApp.instance;
            app.search_box.sensitive = true;
            filter_plugs (app.search_box.get_text ());
#if HAVE_UNITY
            app.update_libunity_quicklist ();
#endif
            if (plug_to_open != null && plug_to_open.has_suffix (plug.code_name)) {
                app.load_plug (plug);
                plug_to_open = null;
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

        public void filter_plugs (string filter) {
            var any_found = false;

            personal_category.filter ();
            hardware_category.filter ();
            network_category.filter ();
            system_category.filter ();

            if (personal_category.has_child ()) {
                any_found = true;
            }

            if (hardware_category.has_child ()) {
                any_found = true;
            }

            if (network_category.has_child ()) {
                any_found = true;
            }

            if (system_category.has_child ()) {
                any_found = true;
            }

            if (any_found) {
                SwitchboardApp.instance.hide_alert ();
            } else {
                SwitchboardApp.instance.show_alert (_("No Results for “%s”".printf (filter)), _("Try changing search terms."), "edit-find-symbolic");
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
