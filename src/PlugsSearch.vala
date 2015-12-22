/***
BEGIN LICENSE
Copyright (C) 2015 elementary OS LLC.
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

author:  2015  Kay van der Zander<kay20@hotmail.com> 
***/

namespace Switchboard {

    public struct search_entry {
        string plug_name;
        string ui_elements;
        string open_window;
    }

    public class PlugsSearch {
        
        public Gee.ArrayList<search_entry?> entries;
        public bool ready {get; private set;}

        public PlugsSearch () {
            ready = false;
            entries = new Gee.ArrayList<search_entry?>();
            cache_search_entries.begin((obj, res) => {
                cache_search_entries.end (res);
                ready = true;
            });
        }

        // key ("%s → %s".printf (display_name, _("Network Time")))
        // value( "")
        public async void cache_search_entries () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();

            foreach (var plug in plugsmanager.get_plugs ()) {
                var tmp_entries = yield plug.search ("");
                string[] keys = tmp_entries.keys.to_array ();
                string[] values = tmp_entries.values.to_array ();
                debug ("plugsSearch: keys %d ", keys.length);
                debug ("plugsSearch: values %d ", values.length);

                for (int i = 0; i < tmp_entries.size; i++) {
                    debug ("plugsSearch: keys: %s ", keys[i]);
                    debug ("plugsSearch: values: %s ", values[i]);
                    string [] tmp = keys[i].split(" → ");
                    search_entry tmp_entry = search_entry ();
                    tmp_entry.plug_name = tmp[0];
                    string ui_elements_name = keys[i];
                    tmp_entry.ui_elements = ui_elements_name;
                    tmp_entry.open_window = values[i];
                    if (tmp_entry.ui_elements == null) {
                        tmp_entry.ui_elements = " ";                    
                    }

                    if (tmp_entry.open_window == null) {
                        tmp_entry.open_window = "";                    
                    }

                    entries.add (tmp_entry);
                    debug ("plugsSearch: add open window: %s ", tmp_entry.open_window);
                    debug ("plugsSearch: add ui elements: %s ", tmp_entry.ui_elements);
                    debug ("plugsSearch: add plug name: %s ", tmp_entry.plug_name);
                }
            }
        }
    }
}
