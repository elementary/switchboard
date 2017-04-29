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

namespace Switchboard {

    public enum WindowState {
        NORMAL = 0,
        MAXIMIZED = 1
    }

    public static int main (string[] args) {

        // Only known plug that requires GtkClutter is switchboard-plug-display
        GtkClutter.init (ref args);

        var app = SwitchboardApp.instance;
        return app.run (args);
    }

    public class SwitchboardApp : Granite.Application {
        private Gtk.Window main_window;
        private Gtk.Stack stack;
        private Gtk.HeaderBar headerbar;

        private Granite.Widgets.AlertView alert_view;
        private Gtk.ScrolledWindow category_scrolled;
        private Gtk.Button navigation_button;
        public Switchboard.CategoryView category_view;

        private Gee.LinkedList <string> loaded_plugs;
        private string all_settings_label = _("All Settings");

        public Gee.ArrayList <Switchboard.Plug> previous_plugs;
        public Switchboard.Plug current_plug;
        public Gtk.SearchEntry search_box { public get; private set; }

        private GLib.Settings settings;
        private int default_width = 0;
        private int default_height = 0;

        private static string? plug_to_open = null;
        private static string? open_window  = null;
        private static string? link  = null;
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
            application_id = "org.pantheon.switchboard";
            program_name = _("System Settings");
            app_years = "2011-2016";
            exec_name = "switchboard";
            app_launcher = exec_name+".desktop";
            flags |= ApplicationFlags.HANDLES_OPEN;

            build_version = "2.0";
            app_icon = "preferences-desktop";
            main_url = "https://github.com/elementary/switchboard";
            bug_url = "https://github.com/elementary/switchboard/issues";
            help_url = "https://elementaryos.stackexchange.com/questions/tagged/settings";
            translate_url = "https://l10n.elementary.io/projects/switchboard";
            about_authors = {"Avi Romanoff <avi@elementaryos.org>", "Corentin Noël <tintou@mailoo.org>", null};
            about_translators = _("translator-credits");
            about_license_type = Gtk.License.GPL_3_0;

            if (GLib.AppInfo.get_default_for_uri_scheme ("settings") == null) {
                var appinfo = new GLib.DesktopAppInfo (app_launcher);
                try {
                    appinfo.set_as_default_for_type ("x-scheme-handler/settings");
                } catch (Error e) {
                    critical ("Unable to set default for the settings scheme: %s", e.message);
                }
            }
        }

        public static SwitchboardApp _instance = null;

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
                    open_window  = parts[1];
                } else {
                    plug_to_open = gcc_to_switchboard_code_name (name);
                }
            }

            activate ();
        }

        public override void activate () {
            var plugsmanager = Switchboard.PlugsManager.get_default ();
            var setting = new Settings ("org.pantheon.switchboard.preferences");
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
            settings = new GLib.Settings ("org.pantheon.switchboard.saved-state");

            build ();

            Gtk.main ();
        }

        public void hide_alert () {
            stack.set_visible_child_full ("main", Gtk.StackTransitionType.NONE);
        }

        public void show_alert (string primary_text, string secondary_text, string icon_name) {
            alert_view.show_all ();
            alert_view.title = primary_text;
            alert_view.description = secondary_text;
            alert_view.icon_name = icon_name;
            stack.set_visible_child_full ("alert", Gtk.StackTransitionType.NONE);
        }

        public void load_plug (Switchboard.Plug plug) {
            //FIXME lower priority for gcc plugs due crash bug #1528361
            var priority = GLib.Priority.DEFAULT_IDLE;
            if (plug.code_name.contains ("-gcc-")) {
                priority = GLib.Priority.LOW;
            }

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
                        debug ("open section:%s of plug: %s",entry.open_window, plug.display_name);
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
            }, priority);

        }

#if HAVE_UNITY
        // Updates items in quicklist menu using the Unity quicklist api.
        public void update_libunity_quicklist () {
            var launcher = Unity.LauncherEntry.get_for_desktop_id (app_launcher);
            var quicklist = new Dbusmenu.Menuitem ();

            var personal_item = add_quicklist_for_category (Switchboard.Plug.Category.PERSONAL);
            if (personal_item != null) {
                quicklist.child_append (personal_item);
            }

            var hardware_item = add_quicklist_for_category (Switchboard.Plug.Category.HARDWARE);
            if (hardware_item != null) {
                quicklist.child_append (hardware_item);
            }

            var network_item = add_quicklist_for_category (Switchboard.Plug.Category.NETWORK);
            if (network_item != null) {
                quicklist.child_append (network_item);
            }

            var system_item = add_quicklist_for_category (Switchboard.Plug.Category.SYSTEM);
            if (system_item != null) {
                quicklist.child_append (system_item);
            }

            if (personal_item != null && hardware_item != null && network_item != null && system_item != null) {
                launcher.quicklist = quicklist;
            }
        }
#endif

        private void build () {
            category_view = new Switchboard.CategoryView (plug_to_open);
            category_view.margin_top = 12;
            category_view.plug_selected.connect ((plug) => load_plug (plug));
            category_view.load_default_plugs.begin ();

            category_scrolled = new Gtk.ScrolledWindow (null, null);
            category_scrolled.add_with_viewport (category_view);

            alert_view = new Granite.Widgets.AlertView ("", "", "");
            alert_view.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_named (alert_view, "alert");
            stack.add_named (category_scrolled, "main");

            main_window = new Gtk.Window();
            main_window.application = this;
            main_window.icon_name = app_icon;
            main_window.title = program_name;
            main_window.add (stack);

            restore_saved_state ();
            setup_toolbar ();

            main_window.set_default_size (default_width, default_height);
            main_window.set_size_request (910, 640);
            main_window.set_titlebar (headerbar);
            main_window.show_all ();

            navigation_button.hide ();

            add_window (main_window);

            var quit_action = new SimpleAction ("quit", null);
            add_action (quit_action);
            add_accelerator ("<Control>q", "app.quit", null);

            quit_action.activate.connect (() => {
                main_window.destroy ();
            });

            main_window.destroy.connect (shut_down);
            main_window.delete_event.connect (() => {
                update_saved_state ();
                return false;
            });

            main_window.window_state_event.connect ((event) => {
                if (event.new_window_state == Gdk.WindowState.MAXIMIZED) {
                    settings.set_enum ("window-state", WindowState.MAXIMIZED);
                } else {
                    settings.set_enum ("window-state", WindowState.NORMAL);
                }

                return false;
            });

            main_window.size_allocate.connect (() => {
                if (opened_directly) {
                    search_box.sensitive = false;
                }
            });

            if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
                show_alert (_("No Settings Found"), _("Install some and re-launch Switchboard."), "dialog-warning");
                search_box.sensitive = false;
            } else {
                search_box.sensitive = true;
                search_box.has_focus = true;
#if HAVE_UNITY
                update_libunity_quicklist ();
#endif
            }
        }

        private void shut_down () {
            if (current_plug != null) {
                current_plug.hidden ();
            }

            Gtk.main_quit ();
        }

        private void restore_saved_state () {
            // Restore window's state
            default_width = settings.get_int ("window-width");
            default_height = settings.get_int ("window-height");
            var position = settings.get_strv ("position");

            if (settings.get_enum ("window-state") == WindowState.MAXIMIZED) {
                main_window.maximize ();
            } else {
                if (position.length != 2) {
                    main_window.window_position = Gtk.WindowPosition.CENTER;
                } else {
                    main_window.move (int.parse (position[0]), int.parse (position[1]));
                }
            }
        }

        private void update_saved_state () {
            // Update saved state of window
            if (settings.get_enum ("window-state") == WindowState.NORMAL) {
                int width, height, x, y;
                main_window.get_size (out width, out height);
                main_window.get_position (out x, out y);
                settings.set_int ("window-width", width);
                settings.set_int ("window-height", height);
                string[] position = {x.to_string (), y.to_string ()};
                settings.set_strv ("position", position);
            }
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
            category_scrolled.hide ();
        }

        // Switches back to the icons
        private bool switch_to_icons () {
            if (stack.transition_type == Gtk.StackTransitionType.NONE) {
                stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
            }

            previous_plugs.clear ();
            category_scrolled.show ();
            stack.set_visible_child (category_scrolled);
            current_plug.hidden ();

            // Reset state
            headerbar.title = program_name;
            search_box.set_text ("");
            search_box.sensitive = Switchboard.PlugsManager.get_default ().has_plugs ();

            if (search_box.sensitive) {
                search_box.has_focus = true;
            }

            return true;
        }

        // Sets up the toolbar for the Switchboard app
        private void setup_toolbar () {
            // Global toolbar widgets
            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.title = program_name;

            // Searchbar
            search_box = new Gtk.SearchEntry ();
            search_box.placeholder_text = _("Search Settings");
            search_box.margin_right = 5;
            search_box.sensitive = false;
            search_box.changed.connect(() => {
                category_view.filter_plugs(search_box.get_text ());
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

            // Focus typing to the search bar
            main_window.key_press_event.connect ((event) => {
                // alt+left should go back to all settings
                if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0 && event.keyval == Gdk.Key.Left) {
                    navigation_button.clicked ();
                    return false;
                }

                // Down key from search_bar should move focus to CategoryVIew
                if (search_box.has_focus && event.keyval == Gdk.Key.Down) {
                    category_view.grab_focus_first_icon_view ();
                    return false;
                }

                // arrow key is being used by CategoryView to navigate
                if (event.keyval in NAVIGATION_KEYS)
                    return false;

                // Don't focus if it is a modifier or if search_box is already focused
                if ((event.is_modifier == 0) && !search_box.has_focus)
                    search_box.grab_focus ();

                return false;
            });

            navigation_button = new Gtk.Button ();
            navigation_button.get_style_context ().add_class ("back-button");
            navigation_button.clicked.connect (handle_navigation_button_clicked);

            main_window.button_release_event.connect ((event) => {
                // On back mouse button pressed
                if (event.button == 8) {
                    navigation_button.clicked ();
                }

                return false;
            });

            // Add everything to the toolbar
            headerbar.pack_start (navigation_button);
            headerbar.pack_end (search_box);
        }

#if HAVE_UNITY
        private Dbusmenu.Menuitem? add_quicklist_for_category (Switchboard.Plug.Category category) {
            // Create menuitem for this category
            var category_item = new Dbusmenu.Menuitem ();
            category_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, CategoryView.get_category_name (category));

            var plugs = new Gee.ArrayList<Plug?> ();
            switch (category) {
                case Switchboard.Plug.Category.PERSONAL:
                    plugs = category_view.personal_category.get_plugs ();
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    plugs = category_view.hardware_category.get_plugs ();
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    plugs = category_view.network_category.get_plugs ();
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    plugs = category_view.system_category.get_plugs ();
                    break;
                default:
                    return null;
            }

            bool empty = true;

            foreach (var plug in plugs) {
                var item = new Dbusmenu.Menuitem ();
                item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, plug.display_name);

                // When item is clicked, open corresponding plug
                item.item_activated.connect (() => {
                    load_plug (plug);
                    activate ();
                });

                // Add item to correct category
                category_item.child_append (item);
                empty = false;
            }

            return (empty ? null : category_item);
        }
#endif

        private string? gcc_to_switchboard_code_name (string gcc_name) {
            // list of names taken from GCC's shell/cc-panel-loader.c
            switch (gcc_name) {
                case "background": return "pantheon-desktop";
                case "bluetooth": return "network-gcc-bluetooth";
                case "color": return "hardware-gcc-color";
                case "datetime": return "system-pantheon-datetime";
                case "display": return "system-pantheon-display";
                case "info": return "system-pantheon-about";
                case "keyboard": return "hardware-pantheon-keyboard";
                case "network": return "pantheon-network";
                case "power": return "system-pantheon-power";
                case "printers": return "hardware-gcc-printer";
                case "privacy": return "pantheon-security-privacy";
                case "region": return "system-pantheon-locale";
                case "sound": return "hardware-gcc-sound";
                case "universal-access": return "system-gcc-universalaccess";
                case "user-accounts": return "system-pantheon-useraccounts";
                case "wacom": return "hardware-gcc-wacom";
                case "notifications": return "personal-pantheon-notifications";

                // not available on our system
                case "search":
                case "sharing":
                    return null;
            }

            return null;
        }
    }
}

