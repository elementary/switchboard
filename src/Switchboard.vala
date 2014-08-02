/***
BEGIN LICENSE
Copyright (C) 2011-2012 Avi Romanoff <aviromanoff@gmail.com>
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 3, as published
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranties of
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program.  If not, see <http://www.gnu.org/licenses/>.
END LICENSE
***/

namespace Switchboard {

    [CCode (cname = "cheese_gtk_init")]
    public extern static bool cheese_gtk_init ([CCode (array_length_pos = 0.9)] ref unowned string[] argv);

    public enum WindowState {
        NORMAL = 0,
        MAXIMIZED = 1
    }

    public static int main (string[] args) {

        // FIXME the gcc user-accounts plug requires cheese to be initialized before gtk,
        //       otherwise it will crash switchboard if it's loaded before the window and
        //       all its widgets are displayed.
        cheese_gtk_init (ref args);

        var app = new SwitchboardApp ();
        return app.run (args);
    }

    public class SwitchboardApp : Granite.Application {
        private Gtk.Window main_window;
        private Gtk.Stack stack;
        private Gtk.HeaderBar headerbar;

        private Granite.Widgets.EmbeddedAlert alert_view;
        private Gtk.ScrolledWindow category_scrolled;
        private Switchboard.NavigationButton navigation_button;
        private Switchboard.CategoryView category_view;

        private Gee.LinkedList <string> loaded_plugs;
        private string all_settings_label = _("All Settings");

        public Switchboard.Plug current_plug;
        public Gtk.SearchEntry search_box { public get; private set; }

        private GLib.Settings settings;
        private int default_width = 0;
        private int default_height = 0;

        private static string? plug_to_open = null;
        private static bool should_animate_next_transition = true;

        static const OptionEntry[] entries = {
            { "open-plug", 'o', 0, OptionArg.STRING, ref plug_to_open, N_("Open a plug"), "PLUG_NAME" },
            { null }
        };

        construct {
            application_id = "org.elementary.switchboard";
            program_name = _("System Settings");
            app_years = "2011-2014";
            exec_name = "switchboard";
            app_launcher = exec_name+".desktop";
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

            build_version = "2.0";
            app_icon = "preferences-desktop";
            main_url = "https://launchpad.net/switchboard";
            bug_url = "https://bugs.launchpad.net/switchboard";
            help_url = "https://answers.launchpad.net/switchboard";
            translate_url = "https://translations.launchpad.net/switchboard";
            about_authors = {"Avi Romanoff <avi@elementaryos.org>", "Corentin Noël <tintou@mailoo.org>", null};

            about_license_type = Gtk.License.GPL_3_0;
        }

        public override int command_line (ApplicationCommandLine command_line) {
            hold ();
            int res = _command_line (command_line);
            release ();
            return res;
        }

        private int _command_line (ApplicationCommandLine command_line) {
            var context = new OptionContext ("");
            context.add_main_entries (entries, "switchboard ");
            context.add_group (Gtk.get_option_group (true));

            string[] args = command_line.get_arguments ();

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);

                // we have an unparsed argument. Assume that it's a gcc plug name
                if (tmp.length > 1) {
                    plug_to_open = gcc_to_switchboard_code_name (tmp[1]);
                }
            } catch (Error e) {
                warning (e.message);
                return 0;
            }

            if (DEBUG)
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
            else
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;

            if (plug_to_open != null) {
                var plugsmanager = Switchboard.PlugsManager.get_default ();
                foreach (var plug in plugsmanager.get_plugs ()) {
                    if (plug_to_open.has_suffix (plug.code_name)) {
                        load_plug (plug);
                        plug_to_open = null;
                        break;
                    }
                }
                // If app is already running, present the current window.
                if (get_windows () != null) {
                    get_windows ().data.present ();
                    return 1;
                }

                // If plug_to_open was set from the command line
                should_animate_next_transition = false;
            }

            loaded_plugs = new Gee.LinkedList <string> ();
            Switchboard.PlugsManager.get_default ();
            settings = new GLib.Settings ("org.pantheon.switchboard.saved-state");
            build ();
            category_view.load_default_plugs.begin ();
            Gtk.main ();

            return 0;
        }

        public void hide_alert () {
            alert_view.no_show_all = true;
            alert_view.hide ();
            stack.set_visible_child (category_scrolled);
        }

        public void show_alert (string primary_text, string secondary_text, Gtk.MessageType type) {
            alert_view.no_show_all = false;
            alert_view.show_all ();
            alert_view.set_alert (primary_text, secondary_text, null, true, type);
            stack.set_visible_child (alert_view);
        }

        public void load_plug (Switchboard.Plug plug) {
            Idle.add (() => {
                if (!loaded_plugs.contains (plug.code_name)) {
                    stack.add_named (plug.get_widget (), plug.code_name);
                    loaded_plugs.add (plug.code_name);
                }

                // Launch plug's executable
                navigation_button.set_sensitive (true);
                navigation_button.set_text (all_settings_label);
                navigation_button.show ();
                headerbar.title = plug.display_name;
                current_plug = plug;
                switch_to_plug (plug);

                return false;
            });
        }

#if HAVE_UNITY
        // Updates items in quicklist menu using the Unity quicklist api.
        public void update_libunity_quicklist () {
            var launcher = Unity.LauncherEntry.get_for_desktop_id (app_launcher);
            var quicklist = new Dbusmenu.Menuitem ();

            var personal_item = add_quicklist_for_category (Switchboard.Plug.Category.PERSONAL);
            if (personal_item != null)
                quicklist.child_append (personal_item);

            var hardware_item = add_quicklist_for_category (Switchboard.Plug.Category.HARDWARE);
            if (hardware_item != null)
                quicklist.child_append (hardware_item);

            var network_item = add_quicklist_for_category (Switchboard.Plug.Category.NETWORK);
            if (network_item != null)
                quicklist.child_append (network_item);

            var system_item = add_quicklist_for_category (Switchboard.Plug.Category.SYSTEM);
            if (system_item != null)
                quicklist.child_append (system_item);

            if (personal_item != null && hardware_item != null && network_item != null && system_item != null)
                launcher.quicklist = quicklist;
        }
#endif

        private void build () {
            main_window = new Gtk.Window();
            add_window (main_window);

            // Set up defaults
            main_window.title = program_name;
            main_window.icon_name = app_icon;

            // Set up window
            restore_saved_state ();
            main_window.set_default_size (default_width, default_height);
            main_window.set_size_request (500, 300);
            main_window.destroy.connect (shut_down);
            main_window.delete_event.connect (() => {
                update_saved_state ();
                return false;
            });
            main_window.window_state_event.connect ((event) => {
                if (event.new_window_state == Gdk.WindowState.MAXIMIZED)
                    settings.set_enum ("window-state", WindowState.MAXIMIZED);
                else
                    settings.set_enum ("window-state", WindowState.NORMAL);

                return false;
            });
            setup_toolbar ();

            // Set up accelerators (hotkeys)
            var accel_group = new Gtk.AccelGroup ();
            uint accel_key;
            Gdk.ModifierType accel_mod;
            var accel_flags = Gtk.AccelFlags.LOCKED;
            Gtk.accelerator_parse ("<Control>q", out accel_key, out accel_mod);
            main_window.add_accel_group (accel_group);
            accel_group.connect (accel_key, accel_mod, accel_flags, () => {
                main_window.destroy ();
                return true;
            });

            category_view = new Switchboard.CategoryView (plug_to_open);
            category_view.plug_selected.connect ((plug) => load_plug (plug));
            category_view.margin_top = 12;

            category_scrolled = new Gtk.ScrolledWindow (null, null);
            category_scrolled.add_with_viewport (category_view);
            category_scrolled.set_vexpand (true);

            // Set up UI
            alert_view = new Granite.Widgets.EmbeddedAlert ();
            alert_view.set_vexpand (true);
            alert_view.no_show_all = true;

            stack = new Gtk.Stack ();
            stack.expand = true;
            stack.add_named (alert_view, "alert");
            stack.add_named (category_scrolled, "main");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            main_window.add (stack);
            main_window.set_application (this);
            main_window.show_all ();
            navigation_button.hide ();

            main_window.size_allocate.connect (() => {
                category_view.recalculate_columns ();
            });

            if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
                show_alert (_("No settings found"), _("Install some and re-launch Switchboard"), Gtk.MessageType.WARNING);
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
            if (current_plug != null)
                current_plug.hidden ();

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
                if (position.length != 2)
                    main_window.window_position = Gtk.WindowPosition.CENTER;
                else
                    main_window.move (int.parse (position[0]), int.parse (position[1]));
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

        // Change Switchboard title back to "Switchboard"
        private void reset_title () {
            headerbar.title = program_name;
        }

        // Handles clicking the navigation button
        private void handle_navigation_button_clicked () {
            if (navigation_button.get_text () == all_settings_label) {
                switch_to_icons ();
                navigation_button.hide ();
            } else {
                switch_to_plug (current_plug);
                navigation_button.set_text (all_settings_label);
            }
        }

        // Switches to the given plug
        private void switch_to_plug (Switchboard.Plug plug) {
            if (should_animate_next_transition == false) {
                stack.set_transition_type (Gtk.StackTransitionType.NONE);
                should_animate_next_transition = true;
            } else if (stack.transition_type == Gtk.StackTransitionType.NONE) {
                stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
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
            category_scrolled.show ();
            stack.set_visible_child (category_scrolled);
            current_plug.hidden ();

            // Reset state
            reset_title ();
            search_box.set_text ("");
            search_box.sensitive = Switchboard.PlugsManager.get_default ().has_plugs ();

            if (search_box.sensitive)
                search_box.has_focus = true;

            return true;
        }

        // Sets up the toolbar for the Switchboard app
        private void setup_toolbar () {
            // Global toolbar widgets
            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.title = program_name;
            main_window.set_titlebar (headerbar);

            // Searchbar
            search_box = new Gtk.SearchEntry ();
            search_box.placeholder_text = _("Search Settings");
            search_box.margin_right = 5;
            search_box.sensitive = false;
            search_box.changed.connect(() => {
                category_view.filter_plugs(search_box.get_text ());
            });

            // Focus typing to the search bar
            main_window.key_press_event.connect ((event) => {
                // Don't focus if it is a modifier or if search_box is already focused.
                if ((event.is_modifier == 0) && !search_box.has_focus)
                    search_box.grab_focus ();

                return false;
            });

            // Nav button
            navigation_button = new NavigationButton ();
            navigation_button.clicked.connect (handle_navigation_button_clicked);
            navigation_button.sensitive = false;

            // Add everything to the toolbar
            headerbar.pack_start (navigation_button);
            headerbar.pack_end (search_box);
        }

#if HAVE_UNITY
        private Dbusmenu.Menuitem? add_quicklist_for_category (Switchboard.Plug.Category category) {
            // Create menuitem for this category
            var category_item = new Dbusmenu.Menuitem ();
            category_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, CategoryView.get_category_name (category));

            Gtk.TreeModelFilter model_filter;
            switch (category) {
                case Switchboard.Plug.Category.PERSONAL:
                    model_filter = (Gtk.TreeModelFilter)category_view.personal_iconview.get_model ();
                    break;
                case Switchboard.Plug.Category.HARDWARE:
                    model_filter = (Gtk.TreeModelFilter)category_view.hardware_iconview.get_model ();
                    break;
                case Switchboard.Plug.Category.NETWORK:
                    model_filter = (Gtk.TreeModelFilter)category_view.network_iconview.get_model ();
                    break;
                case Switchboard.Plug.Category.SYSTEM:
                    model_filter = (Gtk.TreeModelFilter)category_view.system_iconview.get_model ();
                    break;
                default:
                    return null;
            }

            var category_store = model_filter.child_model as Gtk.ListStore;
            bool empty = true;

            category_store.foreach ((model, path, iter) => {
                Switchboard.Plug plug;
                category_store.get (iter, CategoryView.Columns.PLUG, out plug);

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

                return false;
            });

            return (empty ? null : category_item);
        }
#endif

        private string? gcc_to_switchboard_code_name (string gcc_name) {
            // list of names taken from GCC's shell/cc-panel-loader.c
            switch (gcc_name) {
                case "background": return "pantheon-desktop";
                case "bluetooth": return "network-gcc-bluetooth";
                case "color": return "hardware-gcc-color";
                case "datetime": return "system-gcc-date";
                case "display": return "hardware-gcc-display";
                case "info": return "system-pantheon-about";
                case "keyboard": return "hardware-pantheon-keyboard";
                case "network": return "network-gcc-network";
                case "power": return "system-pantheon-power";
                case "printers": return "hardware-gcc-printer";
                case "privacy": return "pantheon-security-privacy";
                case "region": return "hardware-gcc-region";
                case "sound": return "hardware-gcc-sound";
                case "universal-access": return "system-gcc-universalaccess";
                case "user-accounts": return "hardware-gcc-user";
                case "wacom": return "hardware-gcc-wacom";

                // not available on our system
                case "notifications":
                case "search":
                case "sharing":
                    return null;
            }

            return null;
        }
    }
}

#if TRANSLATION
_("Change system and user settings");
_("Center;Control;Panel;Preferences;System;");
_("About");
#endif
