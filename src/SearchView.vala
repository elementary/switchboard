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
        listbox.set_sort_func (sort_func);
        listbox.set_placeholder (alert_view);

        append (listbox);

        load_plugs.begin ();

        search_entry.search_changed.connect (() => {
            alert_view.title = _("No Results for “%s”").printf (search_entry.text);

            if (search_entry.text.length > 0) {
                listbox.invalidate_filter ();
                listbox.invalidate_sort ();
                listbox.select_row (null);
            }
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

        bool valid = search_text.down () in ((SearchRow) listbox_row).last_item.down ();
        if (valid) {
            ((SearchRow) listbox_row).pattern = search_entry.text;
        }

        return valid;
    }

    private int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var search_text = search_entry.text.down ();
        var row1_label = ((SearchRow) row1).last_item.down ();
        var row2_label = ((SearchRow) row2).last_item.down ();

        if (row1_label.has_prefix (search_text) && !row2_label.has_prefix (search_text)) {
            return -1;
        }

        if (row2_label.has_prefix (search_text) && !row1_label.has_prefix (search_text)) {
            return 1;
        }

        return strcmp (row1_label, row2_label);
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
        public string last_item { get; construct; }
        public string uri { get; construct; }

        private Gtk.Label title;
        private Gtk.Label description_label;

        public string pattern {
            set {
                title.set_markup (highlight_text (last_item, value));
                description_label.set_markup (highlight_text (description, value));
            }
        }

        public SearchRow (string icon_name, string description, string uri) {
            var path = description.split (" → ");
            var last_item = path[path.length - 1];

            Object (
                description: description,
                icon_name: icon_name,
                last_item: last_item,
                uri: uri
            );
        }

        construct {
            var image = new Gtk.Image.from_icon_name (icon_name) {
                icon_size = LARGE
            };

            title = new Gtk.Label (null) {
                halign = START,
                use_markup = true
            };
            title.set_markup (GLib.Markup.escape_text (last_item, -1));

            description_label = new Gtk.Label (null) {
                ellipsize = MIDDLE,
                halign = START,
                use_markup = true
            };
            description_label.set_markup (GLib.Markup.escape_text (description, -1));
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

        private string highlight_text (string _text, string search_term) {
            string text = GLib.Markup.escape_text (_text, -1);

            if (search_term.length <= 0) {
                return text;
            }

            try {
                Regex regex = new Regex (Regex.escape_string (search_term), RegexCompileFlags.CASELESS);
                string highlighted_text = regex.replace (text, text.length, 0, "<b>\\0</b>");
                return escape_markup_but_preserve_b_tags (highlighted_text);
            } catch (Error e) {
                return text;
            }
        }

        private string escape_markup_but_preserve_b_tags (string text) {
            string escaped_text = GLib.Markup.escape_text(text, -1);
            escaped_text = escaped_text.replace("&lt;b&gt;", "<b>").replace("&lt;/b&gt;", "</b>");
            escaped_text = escaped_text.replace("&amp;amp;", "&amp;");
            return escaped_text;
        }
    }
}
