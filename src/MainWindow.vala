/*
* Copyright (c) 2011-2017 elementary LLC (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
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
* Authored by: Avi Romanoff <avi@romanoff.me>
*/

public class Switchboard.MainWindow : Gtk.Window {
    private Granite.Widgets.AlertView alert_view;
    private const uint[] NAVIGATION_KEYS = {
        Gdk.Key.Up,
        Gdk.Key.Down,
        Gdk.Key.Left,
        Gdk.Key.Right,
        Gdk.Key.Return
    };

    public Gtk.Button navigation_button;
    public Gtk.HeaderBar headerbar;
    public Gtk.ScrolledWindow category_scrolled;
    public Gtk.SearchEntry search_box { public get; private set; }
    public Gtk.Stack stack;

    public MainWindow (Gtk.Application application) {
        Object (application: application,
                icon_name: "preferences-desktop",
                title: _("System Settings"));
    }

    construct {
        navigation_button = new Gtk.Button ();
        navigation_button.get_style_context ().add_class ("back-button");
        navigation_button.sensitive = false;

        search_box = new Gtk.SearchEntry ();
        search_box.placeholder_text = _("Search Settings");
        search_box.margin_right = 5;
        search_box.sensitive = false;

        headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;
        headerbar.pack_start (navigation_button);
        headerbar.pack_end (search_box);

        alert_view = new Granite.Widgets.AlertView ("", "", "");
        alert_view.no_show_all = true;
        alert_view.vexpand = true;
        alert_view.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        category_scrolled = new Gtk.ScrolledWindow (null, null);
        category_scrolled.set_vexpand (true);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (alert_view, "alert");
        stack.add_named (category_scrolled, "main");

        add (stack);
        set_titlebar (headerbar);

        if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
            show_alert (_("No Settings Found"), _("Install some and re-launch Switchboard."), "dialog-warning");
            search_box.sensitive = false;
        } else {
            search_box.sensitive = true;
            search_box.has_focus = true;
#if HAVE_UNITY
            SwitchboardApp.instance.update_libunity_quicklist ();
#endif
        }

        button_release_event.connect ((event) => {
            // On back mouse button pressed
            if (event.button == 8) {
                navigation_button.clicked ();
            }

            return false;
        });

        key_press_event.connect ((event) => {
            // alt+left should go back to all settings
            if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0 && event.keyval == Gdk.Key.Left) {
                navigation_button.clicked ();
                return false;
            }

            // Down key from search_bar should move focus to CategoryVIew
            if (search_box.has_focus && event.keyval == Gdk.Key.Down) {
                SwitchboardApp.instance.category_view.grab_focus_first_icon_view ();
                return false;
            }

            // arrow key is being used by CategoryView to navigate
            if (event.keyval in NAVIGATION_KEYS) {
                return false;
            }

            // Don't focus if it is a modifier or if main_window.search_box is already focused
            if ((event.is_modifier == 0) && !search_box.has_focus) {
                search_box.grab_focus ();
            }

            return false;
        });

        search_box.changed.connect (() => {
            SwitchboardApp.instance.category_view.filter_plugs (search_box.get_text ());
        });

        search_box.key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Return:
                    SwitchboardApp.instance.category_view.activate_first_item ();
                    return true;
                case Gdk.Key.Escape:
                    search_box.text = "";
                    return true;
                default:
                    break;
            }
            
            return false;
        });
    }

    public void hide_alert () {
        alert_view.no_show_all = true;
        stack.set_visible_child_full ("main", Gtk.StackTransitionType.NONE);
        alert_view.hide ();
    }

    public void reset_state () {
        headerbar.title = _("System Settings");
        search_box.set_text ("");
        search_box.sensitive = Switchboard.PlugsManager.get_default ().has_plugs ();

        if (search_box.sensitive) {
            search_box.has_focus = true;
        }
    }

    public void show_alert (string primary_text, string secondary_text, string icon_name) {
        alert_view.no_show_all = false;
        alert_view.show_all ();
        alert_view.title = primary_text;
        alert_view.description = secondary_text;
        alert_view.icon_name = icon_name;
        stack.set_visible_child_full ("alert", Gtk.StackTransitionType.NONE);
    }

    public bool switch_to_icons () {
        if (stack.transition_type == Gtk.StackTransitionType.NONE) {
            stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        }

        SwitchboardApp.instance.previous_plugs.clear ();
        category_scrolled.show ();
        stack.set_visible_child (category_scrolled);
        SwitchboardApp.instance.current_plug.hidden ();

        reset_state ();

        return true;
    }
}
