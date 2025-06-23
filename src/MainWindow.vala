/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Switchboard.MainWindow : Gtk.ApplicationWindow, PantheonWayland.ExtendedBehavior {
    public string? open_window { get; set; default = null; }
    public bool opened_directly { get; set; default = false; }

    private GLib.HashTable <Gtk.Widget, Switchboard.Plug> plug_widgets;
    private CategoryView category_view;
    private Adw.NavigationView navigation_view;

    construct {
        plug_widgets = new GLib.HashTable <Gtk.Widget, Switchboard.Plug> (null, null);

        category_view = new Switchboard.CategoryView ();

        navigation_view = new Adw.NavigationView () {
            pop_on_escape = false
        };
        navigation_view.add (category_view);

        height_request = 500;
        title = _("System Settings");
        titlebar = new Gtk.Grid () { visible = false };
        child = navigation_view;

        navigation_view.popped.connect (update_navigation);
        navigation_view.pushed.connect (update_navigation);

        /*
        * This is very finicky. Bind size after present else set_titlebar gives us bad sizes
        * Set maximize after height/width else window is min size on unmaximize
        * Bind maximize as SET else get get bad sizes
        */
        var settings = new Settings ("io.elementary.settings");
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("window-maximized")) {
            maximize ();
        }

        settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.SET);

        child.realize.connect (connect_to_shell);
    }

    private void update_navigation () {
        title = navigation_view.visible_page.title;
    }

    public void load_plug (Switchboard.Plug plug) {
        Idle.add (() => {
            var plug_widget = plug.get_widget ();
            if (plug_widget.parent == null) {
                var navigation_page = new Adw.NavigationPage (plug_widget, plug.display_name);
                navigation_page.hidden.connect (plug.hidden);
                navigation_page.shown.connect (plug.shown);

                navigation_view.add (navigation_page);
            }

            if (plug_widgets[plug_widget] == null) {
                plug_widgets[plug_widget] = plug;
            }

            category_view.plug_search_result.foreach ((entry) => {
                if (plug.display_name == entry.plug_name) {
                    if (entry.open_window == null) {
                        plug.search_callback (""); // open default in the switch
                    } else {
                        plug.search_callback (entry.open_window);
                    }
                    debug ("open section:%s of plug: %s", entry.open_window, plug.display_name);
                    return true;
                }

                return false;
            });

            // open window was set by command line argument
            if (open_window != null) {
                plug.search_callback (open_window);
                open_window = null;
            }

            if (opened_directly) {
                navigation_view.animate_transitions = false;
                opened_directly = false;
            } else if (navigation_view.animate_transitions == false) {
                navigation_view.animate_transitions = true;
            }

            navigation_view.push ((Adw.NavigationPage) plug.get_widget ().parent);

            return Source.REMOVE;
        });
    }
}
