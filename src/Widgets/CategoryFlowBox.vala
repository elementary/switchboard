/*
* Copyright (c) 2016 elementary LLC (http://launchpad.net/switchboard)
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
            flowbox.set_sort_func (plug_sort_func);
        }

        public Gee.ArrayList get_plugs () {
            var plugs = new Gee.ArrayList<Plug?> ();
            foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
                plugs.add (((CategoryIcon) child).plug);
            }
            return plugs;
        }

        public new void add (Gtk.Widget widget) {
            flowbox.add (widget);
        }

        public GLib.List<weak Gtk.Widget> get_flow_children () {
            return flowbox.get_children ();
        }

        public void activate_first_child () {
            foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
                if (child.get_child_visible ()) {
                    child.activate ();
                    return;
                }
            }
        }

        public void filter () {
            flowbox.invalidate_filter ();
        }

        public void focus_first_child () {
            flowbox.get_child_at_index (0).grab_focus ();
        }

        public bool has_child () {
           foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
               if (child.get_child_visible ()) {
                   show_all ();
                   return true;
               }
            }
            
            hide ();
            return false;
        }

        private bool plug_filter_func (Gtk.FlowBoxChild child) {
            var filter = SwitchboardApp.instance.search_box.get_text ();
            var plug_name = ((CategoryIcon) child).plug.display_name;
            var plug_search = SwitchboardApp.instance.category_view.plug_search;
            var plug_search_result = SwitchboardApp.instance.category_view.plug_search_result;

            if (plug_search.ready) {
                plug_search_result.clear ();

                foreach (var tmp in plug_search.search_entries) {
                    if (tmp.ui_elements.down ().contains (filter.down ())) {
                        plug_search_result.add (tmp);
                    }
                }

                foreach (var tmp in plug_search_result) {
                    if (tmp.plug_name.down () in plug_name.down ()) {
                        return true;
                    }
                }
            }

            if (filter.down () in plug_name.down ()) {
                return true;
            }
            
            return false;
        }

        private int plug_sort_func (Gtk.FlowBoxChild child_a, Gtk.FlowBoxChild child_b) {
            var plug_name_a = ((CategoryIcon) child_a).plug.display_name;
            var plug_name_b = ((CategoryIcon) child_b).plug.display_name;

            return strcmp (plug_name_a, plug_name_b);
        }
    }
}
