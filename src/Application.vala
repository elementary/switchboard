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
        var app = new SwitchboardApp ();
        return app.run (args);
    }

    public class SwitchboardApp : Gtk.Application {
        public Gtk.SearchEntry search_box { get; private set; }

        private string all_settings_label = N_("All Settings");
        private uint configure_id;

        private GLib.HashTable <Gtk.Widget, Switchboard.Plug> plug_widgets;
        private Gee.ArrayList <Switchboard.Plug> previous_plugs;
        private Gtk.Button navigation_button;
        private Hdy.Deck deck;
        private Hdy.HeaderBar headerbar;
        private Hdy.Window main_window;
        private Switchboard.CategoryView category_view;

        private static bool opened_directly = false;
        private static string? link = null;
        private static string? open_window = null;
        private static string? plug_to_open = null;

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
                critical ("Calling Switchboard directly is unsupported, please use the settings:// scheme instead");
            }

            activate ();
        }

        public override void activate () {
            Hdy.init ();

            var plugsmanager = Switchboard.PlugsManager.get_default ();
            var setting = new Settings ("io.elementary.switchboard.preferences");
            var mapping_dic = setting.get_value ("mapping-override");
            if (link != null && !mapping_dic.lookup (link, "(ss)", ref plug_to_open, ref open_window)) {
                bool plug_found = load_setting_path (link, plugsmanager);

                if (plug_found) {
                    link = null;

                    // If plug_to_open was set from the command line
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

            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });

            plug_widgets = new GLib.HashTable <Gtk.Widget, Switchboard.Plug> (null, null);
            previous_plugs = new Gee.ArrayList <Switchboard.Plug> ();

            var back_action = new SimpleAction ("back", null);
            var quit_action = new SimpleAction ("quit", null);

            add_action (back_action);
            add_action (quit_action);

            set_accels_for_action ("app.back", {"<Alt>Left", "Back"});
            set_accels_for_action ("app.quit", {"<Control>q"});

            navigation_button = new Gtk.Button.with_label (_(all_settings_label));
            navigation_button.action_name = "app.back";
            navigation_button.set_tooltip_markup (
                Granite.markup_accel_tooltip (get_accels_for_action (navigation_button.action_name))
            );
            navigation_button.get_style_context ().add_class ("back-button");

            search_box = new Gtk.SearchEntry ();
            search_box.placeholder_text = _("Search Settings");
            search_box.sensitive = false;

            headerbar = new Hdy.HeaderBar () {
                has_subtitle = false,
                show_close_button = true,
                title = _("System Settings")
            };
            headerbar.pack_start (navigation_button);
            headerbar.pack_end (search_box);

            category_view = new Switchboard.CategoryView (plug_to_open);
            category_view.plug_selected.connect ((plug) => load_plug (plug));
            category_view.load_default_plugs.begin ();

            deck = new Hdy.Deck ();
            deck.add (category_view);

            var searchview = new SearchView ();

            var search_stack = new Gtk.Stack ();
            search_stack.transition_type = Gtk.StackTransitionType.OVER_DOWN_UP;
            search_stack.add (deck);
            search_stack.add (searchview);

            var grid = new Gtk.Grid ();
            grid.attach (headerbar, 0, 0);
            grid.attach (search_stack, 0, 1);

            main_window = new Hdy.Window ();
            main_window.application = this;
            main_window.icon_name = "preferences-desktop";
            main_window.title = _("System Settings");
            main_window.add (grid);
            main_window.set_size_request (640, 480);

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

            search_box.search_changed.connect (() => {
                if (search_box.text_length > 0) {
                    search_stack.visible_child = searchview;
                } else {
                    search_stack.visible_child = deck;
                }
            });

            search_box.key_press_event.connect ((event) => {
                switch (event.keyval) {
                    case Gdk.Key.Return:
                        searchview.activate_first_item ();
                        return Gdk.EVENT_STOP;
                    case Gdk.Key.Down:
                        search_box.move_focus (Gtk.DirectionType.TAB_FORWARD);
                        return Gdk.EVENT_STOP;
                    case Gdk.Key.Escape:
                        search_box.text = "";
                        return Gdk.EVENT_STOP;
                    default:
                        break;
                }

                return Gdk.EVENT_PROPAGATE;
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
                switch (event.keyval) {
                    // arrow or tab key is being used by CategoryView to navigate
                    case Gdk.Key.Up:
                    case Gdk.Key.Down:
                    case Gdk.Key.Left:
                    case Gdk.Key.Right:
                    case Gdk.Key.Return:
                    case Gdk.Key.Tab:
                        return Gdk.EVENT_PROPAGATE;
                }

                // Don't focus if it is a modifier or if search_box is already focused
                if ((event.is_modifier == 0) && !search_box.has_focus) {
                    search_box.grab_focus ();
                }

                return Gdk.EVENT_PROPAGATE;
            });

            main_window.size_allocate.connect (() => {
                if (opened_directly) {
                    search_box.sensitive = false;
                }
            });

            deck.notify["visible-child"].connect (() => {
                update_navigation ();
            });

            deck.notify["transition-running"].connect (() => {
                update_navigation ();
            });

            if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
                category_view.show_alert (_("No Settings Found"), _("Install some and re-launch Switchboard."), "dialog-warning");
                search_box.sensitive = false;
            } else {
                search_box.sensitive = true;
                search_box.has_focus = true;
            }

            Gtk.main ();
        }

        private void update_navigation () {
            if (!deck.transition_running) {
                if (plug_widgets[deck.visible_child] != null) {
                    plug_widgets[deck.visible_child].hidden ();
                }

                if (deck.visible_child == category_view) {
                    headerbar.title = _("System Settings");

                    navigation_button.hide ();

                    search_box.sensitive = Switchboard.PlugsManager.get_default ().has_plugs ();
                    search_box.has_focus = search_box.sensitive;
                } else {
                    plug_widgets[deck.visible_child].shown ();
                    headerbar.title = plug_widgets[deck.visible_child].display_name;

                    if (previous_plugs.size > 1) {
                        navigation_button.label = previous_plugs.@get (0).display_name;
                        previous_plugs.remove_at (previous_plugs.size - 1);
                    } else {
                        navigation_button.label = _(all_settings_label);
                    }
                    navigation_button.show ();

                    search_box.sensitive = false;
                }

                search_box.text = "";
            }
        }

        public void load_plug (Switchboard.Plug plug) {
            Idle.add (() => {
                var plug_widget = plug.get_widget ();
                if (deck.get_children ().find (plug_widget) == null) {
                    deck.add (plug_widget);
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

                if (previous_plugs.size == 0 || previous_plugs.@get (0) != plug) {
                    previous_plugs.add (plug);
                }

                // open window was set by command line argument
                if (open_window != null) {
                    plug.search_callback (open_window);
                    open_window = null;
                }

                if (opened_directly) {
                    deck.transition_duration = 0;
                    opened_directly = false;
                } else if (deck.transition_duration == 0) {
                    deck.transition_duration = 200;
                }

                deck.visible_child = plug.get_widget ();

                return false;
            }, GLib.Priority.DEFAULT_IDLE);
        }

        private void shut_down () {
            if (plug_widgets[deck.visible_child] != null && plug_widgets[deck.visible_child] is Switchboard.Plug) {
                plug_widgets[deck.visible_child].hidden ();
            }

            Gtk.main_quit ();
        }

        // Handles clicking the navigation button
        private void handle_navigation_button_clicked () {
            if (navigation_button.label == _(all_settings_label)) {
                opened_directly = false;

                previous_plugs.clear ();

                deck.transition_duration = 200;
                deck.visible_child = category_view;
            } else {
                load_plug (previous_plugs.@get (0));
                previous_plugs.remove_at (0);
            }
        }

        // Try to find a supported plug, fallback paths like "foo/bar" to "foo"
        public bool load_setting_path (string setting_path, Switchboard.PlugsManager plugsmanager) {
            foreach (var plug in plugsmanager.get_plugs ()) {
                var supported_settings = plug.supported_settings;
                if (supported_settings == null) {
                    continue;
                }

                if (supported_settings.has_key (setting_path)) {
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
    }
}
