/*
* Copyright (c) 2011-2016 elementary LLC (http://launchpad.net/switchboard)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
*/

namespace Switchboard {

    public class Category : Gtk.Grid {

        private Gtk.FlowBox flowbox;

        public Category (Switchboard.Plug.Category category) {
            var category_label = new Gtk.Label (Switchboard.CategoryView.get_category_name (category));
            category_label.get_style_context ().add_class ("category-label");
            category_label.halign = Gtk.Align.START;

            var h_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            h_separator.set_hexpand (true);

            flowbox = new Gtk.FlowBox ();
            flowbox.activate_on_single_click = true;
            flowbox.column_spacing = 12;
            flowbox.row_spacing = 12;
            flowbox.homogeneous = true;
            flowbox.selection_mode = Gtk.SelectionMode.NONE;

            margin_bottom = 12;
            margin_start = 12;
            margin_end = 12;

            column_spacing = 3;
            row_spacing = 6;

            attach (category_label, 0, 0, 1, 1);
            attach (h_separator, 1, 0, 1, 1);
            attach (flowbox, 0, 1, 2, 1);

            flowbox.child_activated.connect ((child) => {
                Switchboard.SwitchboardApp.instance.load_plug (((CategoryIcon) child).plug);
            });

            flowbox.set_filter_func (plug_filter_func);
        }

        private bool plug_filter_func (Gtk.FlowBoxChild child) {
            string filter = SwitchboardApp.instance.search_box.get_text ();
            string plug_name = ((CategoryIcon) child).plug.display_name;
            filter = filter.up ();
            plug_name = plug_name.up ();

            if (plug_name.contains (filter)) {
                return true;
            }
            
            return false;
        }

        public new void add (Gtk.Widget widget) {
            flowbox.add (widget);
        }

        public void activate_first_child () {
            flowbox.get_child_at_index (0).activate ();
        }

        public void filter () {
            flowbox.invalidate_filter ();
        }

        public void focus_first_child () {
            flowbox.get_child_at_index (0).grab_focus ();
        }

        public bool has_child () {
            if (flowbox.get_child_at_index (0) != null) {
               foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
                   if (child.get_child_visible ()) {
                       show_all ();
                       return true;
                   }
                }
            }
            hide ();
            return false;
        }
    }
}

/*
        public Gee.ArrayList<SearchEntry?> plug_search_result;
        private PlugsSearch plug_search;

            plug_search = new PlugsSearch ();
            plug_search_result = new Gee.ArrayList<SearchEntry?> ();


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
*/
