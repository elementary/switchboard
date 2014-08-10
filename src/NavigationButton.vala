/***
    BEGIN LICENSE

    Copyright (C) 2013 elementary, LLC.
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses>

    END LICENSE
***/

namespace Switchboard {

    public class NavigationButton : Gtk.Button {

        private Gtk.Label text;

        public NavigationButton () {
            can_focus = false;
            valign = Gtk.Align.CENTER;
            vexpand = false;
            this.get_style_context ().add_class("back-button");

            Gtk.Box button_b = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            text = new Gtk.Label ("");

            button_b.pack_start (text, true, true, 2);

            this.add (button_b);
        }

        public string get_text () {
            return text.label;
        }

        public void set_text (string text) {
            this.text.label = text;
        }
    }
}