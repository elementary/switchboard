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
public class Switchboard.CategoryIcon : Gtk.FlowBoxChild {
    public unowned Switchboard.Plug plug { get; construct; }

    public CategoryIcon (Switchboard.Plug plug) {
        Object (plug: plug);
    }
    construct {
        width_request = 144;

        var icon = new Gtk.Image.from_icon_name (plug.icon) {
            pixel_size = 32,
            tooltip_text = plug.description
        };

        var plug_name = new Gtk.Label (plug.display_name);
        plug_name.justify = Gtk.Justification.CENTER;
        plug_name.max_width_chars = 18;
        plug_name.wrap = true;
        plug_name.wrap_mode = Pango.WrapMode.WORD_CHAR;

        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            halign = Gtk.Align.CENTER,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        layout.append (icon);
        layout.append (plug_name);

        child = layout;

        plug.visibility_changed.connect (() => {
            changed ();
        });

        plug.notify["can-show"].connect (() => {
            changed ();
        });
    }
}
