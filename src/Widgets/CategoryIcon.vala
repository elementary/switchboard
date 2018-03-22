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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*
*/

namespace Switchboard {

    public class CategoryIcon : Gtk.FlowBoxChild {

        public unowned Switchboard.Plug plug;

        public CategoryIcon (Switchboard.Plug plug_item) {
            plug = plug_item;
            width_request = 144;

            var icon = new Gtk.Image.from_icon_name (plug.icon, Gtk.IconSize.DND);
            icon.tooltip_text = plug.description;

            var plug_name = new Gtk.Label (plug.display_name);
            plug_name.justify = Gtk.Justification.CENTER;
            plug_name.max_width_chars = 18;
            plug_name.wrap = true;
            plug_name.wrap_mode = Pango.WrapMode.WORD_CHAR;
            
            var layout = new Gtk.Grid ();
            layout.halign = Gtk.Align.CENTER;
            layout.margin = 6;
            layout.orientation = Gtk.Orientation.VERTICAL;

            layout.add (icon);
            layout.add (plug_name);

            add (layout);

            plug.visibility_changed.connect (() => {
                changed ();
            });

            plug.notify["can-show"].connect (() => {
                changed ();
            });
        }
    }
}
