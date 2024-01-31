/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*/

public class Switchboard.SearchView : Gtk.Box {
    public Gtk.SearchEntry search_entry { get; construct; }
    private Gtk.ListBox listbox;

    public SearchView (Gtk.SearchEntry search_entry) {
        Object (search_entry: search_entry);
    }

    construct {
        var alert_view = new Granite.Placeholder ("") {
            description = _("Try changing search terms."),
            icon = new ThemedIcon ("edit-find-symbolic")
        };

        unowned SwitchboardApp app = (SwitchboardApp) GLib.Application.get_default ();

        listbox = new Gtk.ListBox () {
            selection_mode = BROWSE
        };
        listbox.add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        listbox.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        listbox.set_filter_func (filter_func);
        listbox.set_placeholder (alert_view);

        var clamp = new Adw.Clamp () {
            child = listbox,
            maximum_size = 800,
            tightening_threshold = 800
        };

        var scrolled = new Gtk.ScrolledWindow () {
            child = clamp
        };

        append (scrolled);

        load_plugs.begin ();

        search_entry.search_changed.connect (() => {
            alert_view.title = _("No Results for “%s”").printf (search_entry.text);
            listbox.invalidate_filter ();
            listbox.select_row (null);
        });

        listbox.row_activated.connect ((row) => {
            app.load_setting_path (
                ((SearchRow) row).uri.replace ("settings://", ""),
                Switchboard.PlugsManager.get_default ()
            );
            search_entry.text = "";
        });
    }

    public void activate_first_item () {
        listbox.get_row_at_y (0).activate ();
    }

    private bool filter_func (Gtk.ListBoxRow listbox_row) {
        var search_text = search_entry.text;
        if (search_text == "" || search_text == null) {
            return true;
        }

        return search_text.down () in ((SearchRow) listbox_row).description.down ();
    }

    private async void load_plugs () {
        var plugs_manager = Switchboard.PlugsManager.get_default ();
        foreach (var plug in plugs_manager.get_plugs ()) {
            var settings = plug.supported_settings;
            if (settings == null || settings.size <= 0) {
                continue;
            }

            string uri = settings.keys.to_array ()[0];

            var search_row = new SearchRow (
                plug.icon,
                plug.display_name,
                uri
            );
            listbox.append (search_row);

            // Using search to get sub settings
            var search_results = yield plug.search ("");
            foreach (var result in search_results.entries) {
                unowned string title = result.key;
                var view = result.value;

                // get uri from plug's supported_settings
                // Use main plug uri as fallback
                string sub_uri = uri;
                if (view != "") {
                    foreach (var setting in settings.entries) {
                        if (setting.value == view) {
                            sub_uri = setting.key;
                            break;
                        }
                    }
                }

                search_row = new SearchRow (
                    plug.icon,
                    title,
                    (owned) sub_uri
                );
                listbox.append (search_row);
            }
        }
    }

    private class SearchRow : Gtk.ListBoxRow {
        public string icon_name { get; construct; }
        public string description { get; construct; }
        public string uri { get; construct; }

        public SearchRow (string icon_name, string description, string uri) {
            Object (
                description: description,
                icon_name: icon_name,
                uri: uri
            );
        }

        construct {
            var image = new Gtk.Image.from_icon_name (icon_name) {
                icon_size = LARGE
            };

            var path = description.split (" → ");
            var last_index = path.length -1 ;

            var title = new Gtk.Label (path[last_index]) {
                halign = START
            };

            var description_label = new Gtk.Label (description) {
                ellipsize = MIDDLE,
                halign = START
            };
            description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
            description_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var grid = new Gtk.Grid () {
                column_spacing = 12
            };
            grid.attach (image, 0, 0, 1, 2);
            grid.attach (title, 1, 0);
            grid.attach (description_label, 1, 1);

            child = grid;
        }
    }
}
