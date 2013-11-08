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

    private static string? plug_to_open = null;

    public class SwitchboardApp : Granite.Application {
        
        private static SwitchboardApp _instance;
        public static SwitchboardApp instance {
            get {
                if (_instance == null)
                    _instance = new SwitchboardApp ();
                return _instance;
            }
        }
        
        private const string[] SUPPORTED_GETTEXT_DOMAINS_KEYS = {"X-Ubuntu-Gettext-Domain", "X-GNOME-Gettext-Domain"};
        
        // Chrome widgets
        Gtk.ProgressBar progress_bar;
        Gtk.Label progress_label;
        public Gtk.SearchEntry search_box;
        Gtk.Toolbar toolbar;
        Gtk.ToolButton navigation_button;
        // Public so we can hide it after show_all()
        public Gtk.ToolItem progress_toolitem;
        // These two wrap the progress bar
        Gtk.ToolItem lspace = new Gtk.ToolItem ();
        Gtk.ToolItem rspace = new Gtk.ToolItem ();
        
        Gtk.Window main_window;
        
        // Current items
        Switchboard.Plug current_plug;
        Gtk.Widget plug_widget;
        
        // Content area widgets
        Gtk.Grid grid;
        Granite.Widgets.EmbeddedAlert alert_view;
        Gtk.ScrolledWindow scrollable_view;
        Switchboard.CategoryView category_view;
        
        construct {
            application_id = "org.elementary.Switchboard";
            program_name = "Switchboard";
            app_years = "2011-2013";
            exec_name = "switchboard";
            app_launcher = exec_name+".desktop";

            build_version = "2.0";
            app_icon = "preferences-desktop";
            main_url = "https://launchpad.net/switchboard";
            bug_url = "https://bugs.launchpad.net/switchboard";
            help_url = "https://answers.launchpad.net/switchboard";
            translate_url = "https://translations.launchpad.net/switchboard";
            about_authors = {"Avi Romanoff <aviromanoff@gmail.com>", "Corentin Noël <tintou@mailoo.org>", null};

            about_license_type = Gtk.License.GPL_3_0;
        }
        
        public override void activate () {
            // If app is already running, present the current window.
            if (get_windows () != null) {
                get_windows ().data.present ();
                return;
            }
            
            if (DEBUG)
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
            else
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
            plugs_manager = new Switchboard.PlugsManager (plug_to_open);
            plugs_manager.open_at_startup.connect ((plug) => {load_plug (plug);});
            build ();
            plugs_manager.activate ();
            
            Gtk.main ();
        }
        
        void build () {
            main_window = new Gtk.Window();

            // Set up defaults
            main_window.title = program_name;
            main_window.icon_name = app_icon;

            // Set up window
            main_window.set_default_size (842, 475);
            main_window.set_size_request (500, 300);
            main_window.window_position = Gtk.WindowPosition.CENTER;
            main_window.destroy.connect (shut_down);
            setup_toolbar ();

            // Set up accelerators (hotkeys)
            var accel_group = new Gtk.AccelGroup ();
            uint accel_key;
            Gdk.ModifierType accel_mod;
            var accel_flags = Gtk.AccelFlags.LOCKED;
            Gtk.accelerator_parse("<Control>q", out accel_key, out accel_mod);
            accel_group.connect(accel_key, accel_mod, accel_flags, () => {
                main_window.destroy();
                return true;
            });
            main_window.add_accel_group (accel_group);

            category_view = new Switchboard.CategoryView ();
            category_view.plug_selected.connect ((plug) => load_plug (plug));
            category_view.margin_top = 12;

            scrollable_view = new Gtk.ScrolledWindow (null, null);

            // Set up UI
            grid = new Gtk.Grid ();
            grid.set_hexpand (true);
            grid.set_vexpand (true);
            grid.attach (toolbar, 0, 0, 1, 1);
            toolbar.set_hexpand (true);

            alert_view = new Granite.Widgets.EmbeddedAlert ();
            alert_view.set_vexpand (true);
            grid.attach (alert_view, 0, 2, 1, 1);

            main_window.add (grid);
            scrollable_view.add_with_viewport (category_view);
            scrollable_view.set_vexpand (true);
            grid.attach (scrollable_view, 0, 1, 1, 1);

            main_window.set_application (this);
            main_window.show_all ();

            main_window.size_allocate.connect (() => {
                var width = grid.get_allocated_width ();
                category_view.recalculate_columns (width);
            });

            alert_view.hide();

            if (count_plugs() <= 0) {
                show_alert(_("No settings found"), _("Install some and re-launch Switchboard"), Gtk.MessageType.WARNING);
                search_box.sensitive = false;
            } else {
                update_libunity_quicklist ();
            }
            
            progress_toolitem.hide ();
        }
        
        void shut_down () {
            if (current_plug != null)
                current_plug.close ();
        }

        public void hide_alert () {
            alert_view.hide ();
            scrollable_view.show ();
        }

        public void show_alert (string primary_text, string secondary_text, Gtk.MessageType type) {
            alert_view.set_alert (primary_text, secondary_text, null, true, type);
            alert_view.show ();
            scrollable_view.hide ();
        }
        
        private int count_plugs () {
            return plugs_manager.plugs.size;
        }

        public void load_plug (Switchboard.Plug plug) {

            // Launch plug's executable
            if (current_plug != plug) {
                
                navigation_button.set_sensitive (true);
                navigation_button.set_icon_name ("go-home");
                current_plug.close ();
                current_plug = plug;
                plug_widget = plug.get_widget ();
                grid.attach (plug_widget, 0, 1, 1, 1);
                switch_to_plug ();
                main_window.title = program_name + " - " + plug.display_name;
            } else {
                navigation_button.set_sensitive(true);
                navigation_button.set_icon_name ("go-home");
                switch_to_plug ();
                main_window.title = program_name + " - " + plug.display_name;
            }
        }

        // Change Switchboard title back to "Switchboard"
        void reset_title () {
            main_window.title = program_name;
        }

        // Handles clicking the navigation button
        void handle_navigation_button_clicked () {
            string icon_name = navigation_button.get_icon_name ();
            if (icon_name == "go-home") {
                switch_to_icons ();
                navigation_button.set_icon_name ("go-previous");
            }
            else {
                switch_to_plug ();
                navigation_button.set_icon_name ("go-home");
            }
        }

        // Switches to the socket view
        void switch_to_plug () {
            search_box.sensitive = false;

            category_view.hide ();
            plug_widget.show_all ();
        }
        
        // Switches back to the icons
        bool switch_to_icons () {
            plug_widget.hide ();
            category_view.show ();

            // Reset state
            reset_title ();
            search_box.set_text ("");
            search_box.sensitive = count_plugs () > 0;
            progress_label.set_text ("");
            progress_bar.fraction = 0.0;
            progress_toolitem.visible = false;
            
            return true;
        }

        // Sets up the toolbar for the Switchboard app
        void setup_toolbar () {

            // Global toolbar widgets
            toolbar = new Gtk.Toolbar ();
            toolbar.get_style_context ().add_class ("primary-toolbar");

            // Spacing
            lspace.set_expand(true);
            rspace.set_expand(true);

            // Progressbar
            var progress_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            progress_label = new Gtk.Label ("");
            progress_label.set_use_markup(true);
            progress_bar = new Gtk.ProgressBar ();
            progress_toolitem = new Gtk.ToolItem ();
            progress_vbox.pack_start(progress_label, true, false, 0);
            progress_vbox.pack_end(progress_bar, false, false, 0);
            progress_toolitem.add(progress_vbox);
            progress_toolitem.set_expand(true);

            // Searchbar
            search_box = new Gtk.SearchEntry ();
            search_box.set_placeholder_text (_("Search Settings"));
            search_box.changed.connect(() => {
                category_view.filter_plugs(search_box.get_text ());
            });
            search_box.sensitive = (count_plugs () > 0);
            var find_toolitem = new Gtk.ToolItem ();
            find_toolitem.add(search_box);
            find_toolitem.margin_right = 6;

            // Focus typing to the search bar
            main_window.key_press_event.connect ((event) => {
                // Don't focus if it is a modifier or if search_box is already focused.
                if ((event.is_modifier == 0) && !search_box.has_focus)
                    search_box.grab_focus ();

                return false;
            });

            // Nav button
            navigation_button = new Gtk.ToolButton (null, null);
            navigation_button.set_icon_name ("go-previous");
            navigation_button.clicked.connect (handle_navigation_button_clicked);
            navigation_button.set_sensitive(false);

            // Add everything to the toolbar
            toolbar.insert (navigation_button, -1);
            toolbar.insert (lspace, -1);
            toolbar.insert (progress_toolitem, -1);
            toolbar.insert (rspace, -1);
            toolbar.insert (find_toolitem, -1);
        }

        // Updates items in quicklist menu using the Unity quicklist api.
        void update_libunity_quicklist () {
            // Fetch launcher
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
            if (empty == false) {
                return category_item;
            } else {
                return null;
            }
        }
    }

    static const OptionEntry[] entries = {
            { "open-plug", 'o', 0, OptionArg.STRING, ref plug_to_open, N_("Open a plug"), "PLUG_NAME" },
            { null }
    };

    public static int main (string[] args) {
        
        Gtk.init (ref args);
        
        var context = new OptionContext("");
        context.add_main_entries(entries, "switchboard ");
        context.add_group(Gtk.get_option_group(true));
        try {
            context.parse(ref args);
        } catch(Error e) { warning (e.message); }
        
        return SwitchboardApp.instance.run (args);
    }
}
