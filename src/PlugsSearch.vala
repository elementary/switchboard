/*-
 * Copyright (c) 2015-2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Kay van der Zander <kay20@hotmail.com>
 */

namespace Switchboard {

    public struct SearchEntry {
        string plug_name;
        string ui_elements;
        string open_window;
    }

    public class PlugsSearch {
        
        public Gee.ArrayList<SearchEntry?> search_entries;
        public bool ready {get; private set;}

        public PlugsSearch () {
            ready = false;
            search_entries = new Gee.ArrayList<SearchEntry?>();
            cache_search_entries.begin((obj, res) => {
                cache_search_entries.end (res);
                ready = true;
            });
        }

        // key ("%s → %s".printf (display_name, _("Network Time")))
        public async void cache_search_entries () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();

            foreach (var plug in plugsmanager.get_plugs ()) {
                var tmp_entries = yield plug.search ("");

                foreach (var entry in tmp_entries.entries) {
                    string [] tmp = entry.key.split(" → ");
                    SearchEntry tmp_entry = SearchEntry ();
                    tmp_entry.plug_name = tmp[0];
                    string ui_elements_name = entry.key;
                    tmp_entry.ui_elements = ui_elements_name;
                    tmp_entry.open_window = entry.value;
                    search_entries.add (tmp_entry);
                    debug ("plugsSearch: add open window: %s ", tmp_entry.open_window);
                    debug ("plugsSearch: add ui elements: %s ", tmp_entry.ui_elements);
                    debug ("plugsSearch: add plug name: %s ", tmp_entry.plug_name);
                }
            }
        }
    }
}
