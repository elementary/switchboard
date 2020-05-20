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
            category_label.vexpand = true;

            var h_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            h_separator.hexpand = true;
            h_separator.valign = Gtk.Align.CENTER;

            flowbox = new Gtk.FlowBox ();
            flowbox.activate_on_single_click = true;
            flowbox.column_spacing = 12;
            flowbox.row_spacing = 12;
            flowbox.homogeneous = true;
            flowbox.min_children_per_line = 5;
            flowbox.max_children_per_line = 5;
            flowbox.selection_mode = Gtk.SelectionMode.NONE;
            flowbox.vexpand = true;

            margin_bottom = 12;
            margin_start = 12;
            margin_end = 12;

            column_spacing = 3;
            row_spacing = 6;

            vexpand = true;

            attach (category_label, 0, 0, 1, 1);
            attach (h_separator, 1, 0, 1, 1);
            attach (flowbox, 0, 1, 2, 1);

            flowbox.child_activated.connect ((child) => {
                ((SwitchboardApp) GLib.Application.get_default ()).load_plug (((CategoryIcon) child).plug);
            });

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

        private int plug_sort_func (Gtk.FlowBoxChild child_a, Gtk.FlowBoxChild child_b) {
            var plug_name_a = ((CategoryIcon) child_a).plug.display_name;
            var plug_name_b = ((CategoryIcon) child_b).plug.display_name;

            return strcmp (plug_name_a, plug_name_b);
        }
    }
}
