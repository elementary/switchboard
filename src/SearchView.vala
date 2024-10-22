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
            listbox.invalidate_filter ();
            listbox.invalidate_sort ();
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
                title.label = markup_string_with_search (last_item, value);
                description_label.label = markup_string_with_search (description, value);
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

        private static string markup_string_with_search (string text, string pattern) {
            const string MARKUP = "%s";

            if (pattern == "") {
                return MARKUP.printf (Markup.escape_text (text));
            }

            // if no text found, use pattern
            if (text == "") {
                return MARKUP.printf (Markup.escape_text (pattern));
            }

            var matchers = Synapse.Query.get_matchers_for_query (
                pattern,
                0,
                RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS
            );

            string? highlighted = null;
            foreach (var matcher in matchers) {
                MatchInfo mi;
                if (matcher.key.match (text, 0, out mi)) {
                    int start_pos;
                    int end_pos;
                    int last_pos = 0;
                    int cnt = mi.get_match_count ();
                    StringBuilder res = new StringBuilder ();
                    for (int i = 1; i < cnt; i++) {
                        mi.fetch_pos (i, out start_pos, out end_pos);
                        warn_if_fail (start_pos >= 0 && end_pos >= 0);
                        res.append (Markup.escape_text (text.substring (last_pos, start_pos - last_pos)));
                        last_pos = end_pos;
                        res.append (Markup.printf_escaped ("<b>%s</b>", mi.fetch (i)));
                        if (i == cnt - 1) {
                            res.append (Markup.escape_text (text.substring (last_pos)));
                        }
                    }
                    highlighted = res.str;
                    break;
                }
            }

            if (highlighted != null) {
                return MARKUP.printf (highlighted);
            } else {
                return MARKUP.printf (Markup.escape_text (text));
            }
        }
    }
}
