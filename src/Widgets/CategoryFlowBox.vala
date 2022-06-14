/*
* Copyright (c) 2016-2019 elementary, Inc. (https://elementary.io)
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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*
*/

namespace Switchboard {
    public class Category : Gtk.Grid {
        public Switchboard.Plug.Category category { get; construct; }

        private Gtk.FlowBox flowbox;

        public Category (Switchboard.Plug.Category category) {
            Object (category: category);
        }

        construct {
            var category_label = new Granite.HeaderLabel (Switchboard.CategoryView.get_category_name (category));

            flowbox = new Gtk.FlowBox () {
                activate_on_single_click = true,
                column_spacing = 12,
                row_spacing = 12,
                max_children_per_line = 5,
                selection_mode = Gtk.SelectionMode.NONE
            };

            valign = Gtk.Align.START;
            column_spacing = 3;
            row_spacing = 6;

            attach (category_label, 0, 0, 1, 1);
            attach (flowbox, 0, 1, 2, 1);

            flowbox.child_activated.connect ((child) => {
                ((SwitchboardApp) GLib.Application.get_default ()).load_plug (((CategoryIcon) child).plug);
            });

            flowbox.set_sort_func (plug_sort_func);
        }

        public Gee.ArrayList get_plugs () {
            var plugs = new Gee.ArrayList<Plug?> ();

            var child = flowbox.get_first_child ();
            while (child != null) {
                plugs.add (((CategoryIcon) child).plug);
                child = child.get_next_sibling ();
            }

            return plugs;
        }

        public new void add (Gtk.Widget widget) {
            flowbox.append (widget);
        }

        public bool has_child () {
            var child = flowbox.get_first_child ();
            while (child != null) {
                if (child.get_child_visible ()) {
                    show ();
                    return true;
                }

                child = child.get_next_sibling ();
            }

            hide ();
            return false;
        }

        private int plug_sort_func (Gtk.FlowBoxChild child_a, Gtk.FlowBoxChild child_b) {
            var plug_name_a = ((CategoryIcon) child_a).plug.display_name;
            var plug_name_b = ((CategoryIcon) child_b).plug.display_name;

            return strcmp (plug_name_a, plug_name_b);
        }
    }
}
