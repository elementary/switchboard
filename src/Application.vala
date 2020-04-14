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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*
* Authored by: Avi Romanoff <avi@romanoff.me>
*/

namespace Switchboard {
    public static int main (string[] args) {
        // Only known plug that requires GtkClutter is switchboard-plug-display
        GtkClutter.init (ref args);

        var app = SwitchboardApp.instance;
        return app.run (args);
    }

    public class SwitchboardApp : Gtk.Application {
        private Gtk.Window main_window;
        private Gtk.Stack stack;
        private Gtk.HeaderBar headerbar;

        private Gtk.Button navigation_button;
        public Switchboard.CategoryView category_view;

        private Gee.LinkedList <string> loaded_plugs;
        private string all_settings_label = _("All Settings");
        private uint configure_id;

        public Gee.ArrayList <Switchboard.Plug> previous_plugs;
        public Switchboard.Plug current_plug;
        public Gtk.SearchEntry search_box { public get; private set; }

        private static string? plug_to_open = null;
        private static string? open_window = null;
        private static string? link = null;
        private static bool opened_directly = false;
        private static bool should_animate_next_transition = true;
        private const uint[] NAVIGATION_KEYS = {
            Gdk.Key.Up,
            Gdk.Key.Down,
            Gdk.Key.Left,
            Gdk.Key.Right,
            Gdk.Key.Return
        };

        construct {
            application_id = "io.elementary.switchboard";
            flags |= ApplicationFlags.HANDLES_OPEN;

            if (GLib.AppInfo.get_default_for_uri_scheme ("settings") == null) {
                var appinfo = new GLib.DesktopAppInfo (application_id + ".desktop");
                try {
                    appinfo.set_as_default_for_type ("x-scheme-handler/settings");
                } catch (Error e) {
                    critical ("Unable to set default for the settings scheme: %s", e.message);
                }
            }
        }

        private static SwitchboardApp _instance = null;
        public static unowned SwitchboardApp instance {
            get {
                if (_instance == null) {
                    _instance = new SwitchboardApp ();
                }
                return _instance;
            }
        }

        public override void open (File[] files, string hint) {
            var file = files[0];
            if (file == null) {
                return;
            }

            if (file.get_uri_scheme () == "settings") {
                link = file.get_uri ().replace ("settings://", "");
                if (link.has_suffix ("/")) {
                    link = link.substring (0, link.last_index_of_char ('/'));
                }

            } else {
                warning ("Calling Switchboard directly is deprecated, please use the settings:// scheme instead");
                var name = file.get_basename ();
                if (":" in name) {
                    var parts = name.split (":");
                    plug_to_open = gcc_to_switchboard_code_name (parts[0]);
                    open_window = parts[1];
                } else {
                    plug_to_open = gcc_to_switchboard_code_name (name);
                }
            }

            activate ();
        }

        public override void activate () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();
            var setting = new Settings ("io.elementary.switchboard.preferences");
            var mapping_dic = setting.get_value ("mapping-override");
            if (link != null && !mapping_dic.lookup (link, "(ss)", ref plug_to_open, ref open_window)) {
                bool plug_found = load_setting_path (link, plugsmanager);

                if (plug_found) {
                    link = null;

                    // If plug_to_open was set from the command line
                    should_animate_next_transition = false;
                    opened_directly = true;
                } else {
                    warning (_("Specified link '%s' does not exist, going back to the main panel").printf (link));
                }
            } else if (plug_to_open != null) {
                foreach (var plug in plugsmanager.get_plugs ()) {
                    if (plug_to_open.has_suffix (plug.code_name)) {
                        load_plug (plug);
                        plug_to_open = null;

                        // If plug_to_open was set from the command line
                        should_animate_next_transition = false;
                        opened_directly = true;
                        break;
                    }
                }
            }

            // If app is already running, present the current window.
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }

            loaded_plugs = new Gee.LinkedList <string> ();
            previous_plugs = new Gee.ArrayList <Switchboard.Plug> ();

            build ();

            Gtk.main ();
        }

        public void load_plug (Switchboard.Plug plug) {
            Idle.add (() => {
                if (!loaded_plugs.contains (plug.code_name)) {
                    stack.add_named (plug.get_widget (), plug.code_name);
                    loaded_plugs.add (plug.code_name);
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

                if (previous_plugs.size == 0 || previous_plugs.@get (0) != plug) {
                    previous_plugs.add (plug);
                }

                // Launch plug's executable
                navigation_button.label = all_settings_label;
                navigation_button.show ();

                headerbar.title = plug.display_name;
                current_plug = plug;

                // open window was set by command line argument
                if (open_window != null) {
                    plug.search_callback (open_window);
                    open_window = null;
                }

                switch_to_plug (plug);
                return false;
            }, GLib.Priority.DEFAULT_IDLE);
        }

        private void build () {
            var back_action = new SimpleAction ("back", null);
            var quit_action = new SimpleAction ("quit", null);

            add_action (back_action);
            add_action (quit_action);

            set_accels_for_action ("app.back", {"<Alt>Left", "Back"});
            set_accels_for_action ("app.quit", {"<Control>q"});

            navigation_button = new Gtk.Button ();
            navigation_button.action_name = "app.back";
            navigation_button.set_tooltip_markup (
                Granite.markup_accel_tooltip (get_accels_for_action (navigation_button.action_name))
            );
            navigation_button.get_style_context ().add_class ("back-button");

            search_box = new Gtk.SearchEntry ();
            search_box.placeholder_text = _("Search Settings");
            search_box.sensitive = false;

            headerbar = new Gtk.HeaderBar ();
            headerbar.has_subtitle = false;
            headerbar.show_close_button = true;
            headerbar.title = _("System Settings");
            headerbar.pack_start (navigation_button);
            headerbar.pack_end (search_box);

            category_view = new Switchboard.CategoryView (plug_to_open);
            category_view.plug_selected.connect ((plug) => load_plug (plug));
            category_view.load_default_plugs.begin ();

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_named (category_view, "main");

            main_window = new Gtk.Window ();
            main_window.application = this;
            main_window.icon_name = "preferences-desktop";
            main_window.title = _("System Settings");
            main_window.add (stack);
            main_window.set_size_request (640, 480);
            main_window.set_titlebar (headerbar);

            int window_x, window_y;
            var rect = Gtk.Allocation ();

            var settings = new GLib.Settings ("io.elementary.switchboard.saved-state");
            settings.get ("window-position", "(ii)", out window_x, out window_y);
            settings.get ("window-size", "(ii)", out rect.width, out rect.height);

            if (window_x != -1 || window_y != -1) {
                main_window.move (window_x, window_y);
            }

            main_window.set_allocation (rect);

            if (settings.get_boolean ("window-maximized")) {
                main_window.maximize ();
            }

            main_window.show_all ();

            navigation_button.hide ();

            add_window (main_window);

            search_box.changed.connect (() => {
                category_view.filter_plugs (search_box.get_text ());
            });

            search_box.key_press_event.connect ((event) => {
                switch (event.keyval) {
                    case Gdk.Key.Return:
                        category_view.activate_first_item ();
                        return true;
                    case Gdk.Key.Escape:
                        search_box.text = "";
                        return true;
                    default:
                        break;
                }

                return false;
            });

            back_action.activate.connect (() => {
                handle_navigation_button_clicked ();
            });

            quit_action.activate.connect (() => {
                main_window.destroy ();
            });

            main_window.button_release_event.connect ((event) => {
                // On back mouse button pressed
                if (event.button == 8) {
                    navigation_button.clicked ();
                }

                return false;
            });

            main_window.destroy.connect (shut_down);

            main_window.configure_event.connect ((event) => {
                if (configure_id != 0) {
                    GLib.Source.remove (configure_id);
                }

                configure_id = Timeout.add (100, () => {
                    configure_id = 0;

                    if (main_window.is_maximized) {
                        settings.set_boolean ("window-maximized", true);
                    } else {
                        settings.set_boolean ("window-maximized", false);

                        main_window.get_allocation (out rect);
                        settings.set ("window-size", "(ii)", rect.width, rect.height);

                        int root_x, root_y;
                        main_window.get_position (out root_x, out root_y);
                        settings.set ("window-position", "(ii)", root_x, root_y);
                    }

                    return false;
                });

                return false;
            });

            main_window.key_press_event.connect ((event) => {
                // Down key from search_bar should move focus to CategoryVIew
                if (search_box.has_focus && event.keyval == Gdk.Key.Down) {
                    search_box.move_focus (Gtk.DirectionType.TAB_FORWARD);
                    return Gdk.EVENT_STOP;
                }

                // arrow key is being used by CategoryView to navigate
                if (event.keyval in NAVIGATION_KEYS)
                    return Gdk.EVENT_PROPAGATE;

                // Don't focus if it is a modifier or if search_box is already focused
                if ((event.is_modifier == 0) && !search_box.has_focus)
                    search_box.grab_focus ();

                return Gdk.EVENT_PROPAGATE;
            });

            main_window.size_allocate.connect (() => {
                if (opened_directly) {
                    search_box.sensitive = false;
                }
            });

            if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
                category_view.show_alert (_("No Settings Found"), _("Install some and re-launch Switchboard."), "dialog-warning");
                search_box.sensitive = false;
            } else {
                search_box.sensitive = true;
                search_box.has_focus = true;
            }
        }

        private void shut_down () {
            if (current_plug != null) {
                current_plug.hidden ();
            }

            Gtk.main_quit ();
        }

        // Handles clicking the navigation button
        private void handle_navigation_button_clicked () {
            if (navigation_button.label == all_settings_label) {
                opened_directly = false;
                search_box.sensitive = true;
                switch_to_icons ();
                navigation_button.hide ();
            } else {
                if (previous_plugs.size > 0 && stack.get_visible_child_name () != "main") {
                    if (current_plug != null) {
                        current_plug.hidden ();
                    }

                    load_plug (previous_plugs.@get (0));
                    previous_plugs.remove_at (0);
                } else {
                    switch_to_plug (current_plug);
                }
            }
        }

        // Try to find a supported plug, fallback paths like "foo/bar" to "foo"
        private bool load_setting_path (string setting_path, Switchboard.PlugsManager plugsmanager) {
            foreach (var plug in plugsmanager.get_plugs ()) {
                var supported_settings = plug.supported_settings;
                if (supported_settings == null) {
                    continue;
                }

                if (supported_settings.has_key (setting_path)) {
                    if (current_plug != null) {
                        current_plug.hidden ();
                    }

                    load_plug (plug);
                    open_window = supported_settings.get (setting_path);
                    return true;
                }
            }

            // Fallback to subpath
            if ("/" in setting_path) {
                int last_index = setting_path.last_index_of_char ('/');
                return load_setting_path (setting_path.substring (0, last_index), plugsmanager);
            }

            return false;
        }

        // Switches to the given plug
        private void switch_to_plug (Switchboard.Plug plug) {
            if (should_animate_next_transition == false) {
                stack.set_transition_type (Gtk.StackTransitionType.NONE);
                should_animate_next_transition = true;
            } else if (stack.transition_type == Gtk.StackTransitionType.NONE) {
                stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            }

            if (previous_plugs.size > 1 && stack.get_visible_child_name () != "main") {
                navigation_button.label = previous_plugs.@get (0).display_name;
                previous_plugs.remove_at (previous_plugs.size - 1);
            } else {
                navigation_button.label = all_settings_label;
            }

            search_box.sensitive = false;
            plug.shown ();
            stack.set_visible_child_name (plug.code_name);
        }

        private bool switch_to_icons () {
            previous_plugs.clear ();
            stack.set_visible_child_full ("main", Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            current_plug.hidden ();

            headerbar.title = _("System Settings");

            search_box.set_text ("");
            search_box.sensitive = Switchboard.PlugsManager.get_default ().has_plugs ();

            if (search_box.sensitive) {
                search_box.has_focus = true;
            }

            return true;
        }

        private string? gcc_to_switchboard_code_name (string gcc_name) {
            // list of names taken from GCC's shell/cc-panel-loader.c
            switch (gcc_name) {
                case "background": return "pantheon-desktop";
                case "bluetooth": return "network-pantheon-bluetooth";
                case "color": return "hardware-gcc-color";
                case "datetime": return "system-pantheon-datetime";
                case "display": return "system-pantheon-display";
                case "info": return "system-pantheon-about";
                case "keyboard": return "hardware-pantheon-keyboard";
                case "network": return "pantheon-network";
                case "power": return "system-pantheon-power";
                case "printers": return "pantheon-printers";
                case "privacy": return "pantheon-security-privacy";
                case "region": return "system-pantheon-locale";
                case "sharing": return "pantheon-sharing";
                case "sound": return "hardware-gcc-sound";
                case "universal-access": return "pantheon-accessibility";
                case "user-accounts": return "system-pantheon-useraccounts";
                case "wacom": return "hardware-gcc-wacom";
                case "notifications": return "personal-pantheon-notifications";

                // not available on our system
                case "search":
                    return null;
            }

            return null;
        }
    }
}
