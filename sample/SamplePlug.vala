// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2014 Switchboard Developers (http://launchpad.net/switchboard)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Sample.Plug : Switchboard.Plug {
    private Gtk.Grid main_grid;
    private Gtk.Label hello_label;

    public Plug () {
        Object (category: Category.SYSTEM,
                code_name: "sample-plug",
                display_name: "Sample Plug",
                description: "Does nothing, but it is cool!",
                icon: "system-run",
                supported_settings: new Gee.TreeMap<string, string?> (null, null));
        supported_settings.set ("wallpaper", null);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            hello_label = new Gtk.Label ("Hello World!");
            main_grid.attach (hello_label, 0, 0, 1, 1);
        }

        return main_grid;
    }

    public override void shown () {

    }

    public override void hidden () {

    }

    public override void search_callback (string location) {
        hello_label.label = "Callback : %s".printf (location);
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        return new Gee.TreeMap<string, string> (null, null);
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Sample plug");
    var plug = new Sample.Plug ();
    return plug;
}
