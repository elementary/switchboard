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

    static string plug_to_open;

    [DBus (name = "org.elementary.switchboard")]
    public class SwitchboardApp : Granite.Application {
        
        construct {
            application_id = "org.elementary.Switchboard";
            program_name = "Switchboard";
            app_years = "2011-2012";
            exec_name = "switchboard";
            app_launcher = exec_name+".desktop";

            build_version = VERSION;
            app_icon = APP_ICON;
            main_url = WEBSITE;
            bug_url = BUG_URL;
            help_url = HELP_URL;
            translate_url = TRANSLATE_URL;
            about_authors = AUTHORS;

            about_license_type = Gtk.License.GPL_3_0;
        }

        // Chrome widgets
        Gtk.ProgressBar progress_bar;
        Gtk.Label progress_label;
        Gtk.SearchEntry search_box;
        Gtk.Toolbar toolbar;
        Gtk.ToolButton navigation_button;
        // Public so we can hide it after show_all()
        public Gtk.ToolItem progress_toolitem;
        // These two wrap the progress bar
        Gtk.ToolItem lspace = new Gtk.ToolItem ();
        Gtk.ToolItem rspace = new Gtk.ToolItem ();
        
        Gtk.Spinner loading;
        
        Gtk.Window main_window;

        // Content area widgets
        Gtk.Socket socket;
        Gtk.Grid grid;
        Granite.Widgets.EmbeddedAlert alert_view;
        Gtk.ScrolledWindow scrollable_view;
        Switchboard.CategoryView category_view;

        // Plug data
        bool socket_shown;
        Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();
        Gee.HashMap<string, string>[] plugs;

        string[] plug_places = {"/usr/share/plugs/",
                                "/usr/lib/plugs/",
                                "/usr/local/share/plugs/", 
                                "/usr/local/lib/plugs/"};
        string search_box_buffer = "";

        private const string[] SUPPORTED_GETTEXT_DOMAINS_KEYS = {"X-Ubuntu-Gettext-Domain", "X-GNOME-Gettext-Domain"};

        public SwitchboardApp () {
        }
        
        void build () {
            main_window = new Gtk.Window();

            // Set up defaults
            main_window.title = APP_TITLE;
            main_window.icon_name = APP_ICON;

            // Set up window
            main_window.set_default_size (842, 475);
            main_window.set_size_request (500, 300);
            main_window.window_position = Gtk.WindowPosition.CENTER;
            main_window.destroy.connect (shut_down);
            setup_toolbar ();

            // Set up socket
            socket = new Gtk.Socket ();
            socket.set_hexpand(true);
            socket.set_vexpand(true);

            socket.plug_removed.connect (() => {
                plug_closed ();
                return true;
            });

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

            // ??? Why?
            current_plug["title"] = "";
            current_plug["executable"] = "";

            category_view = new Switchboard.CategoryView ();
            category_view.plug_selected.connect ((title, executable, @extern) => load_plug (title, executable, @extern));
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
                var width = main_window.get_allocated_width ();
                category_view.recalculate_columns (width);
            });

            foreach (var label in category_view.category_labels.values)
                label.hide ();
            foreach (var view in category_view.category_views.values)
                view.hide ();

            alert_view.hide();

            loading = new Gtk.Spinner ();
            loading.set_vexpand(true);
            loading.halign = Gtk.Align.CENTER;
            loading.valign = Gtk.Align.CENTER;
            loading.width_request = 72;
            loading.height_request = 72;
            loading.start ();

            grid.attach (socket, 0, 1, 1, 1);
            socket.hide ();
            grid.attach (loading, 0, 1, 1, 1);
            loading.hide ();

            var any_plugs = false;

            socket.plug_added.connect (() => {
                if (loading.visible) {
                    loading.hide ();
                    socket.show_all ();
                }
            });

            foreach (string place in plug_places)
                if (enumerate_plugs (place))
                    any_plugs = true;

            if (!any_plugs) {
                show_alert(_("No settings found"), _("Install some and re-launch Switchboard"), Gtk.MessageType.WARNING);
                search_box.sensitive = false;
            } else {
                update_libunity_quicklist ();
            }
            
            bool found = false;
            if (plug_to_open != null) {
                foreach (var plug in plugs) {
                    if (plug["id"] == plug_to_open) {
                        load_plug (plug["title"], plug["exec"], plug["extern"] == "1");
                        found = true;
                    }
                }
                if (!found) {
                    critical ("Couldn't find %s among the loaded settings.", plug_to_open);
                }
            }
            
            foreach (var store in category_view.category_store.values) {
                store.foreach ((model, path, iter) => {
                    store.set_value (iter, 3, true);
                    return false;
                });
            }
            
            progress_toolitem.hide ();
        }
        
        void shut_down () {
            plug_closed ();
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

        public void load_plug (string title, string executable, bool @extern) {
            debug ("Selected plug: title %s | executable %s", title, executable);

            // Launch plug's executable
            if (current_plug["title"] != title || !socket.visible) {
                try {
                    // The plug is already selected
                    debug(_("Closing plug \"%s\" in Switchboard controller..."), current_plug["title"]);
                    plug_closed ();
                    
                    string[] cmd_exploded = (executable!=null)?executable.split (" "):null;
                    GLib.Process.spawn_async (File.new_for_path (cmd_exploded[0]).get_parent ().
                        get_path (), cmd_exploded, null, SpawnFlags.SEARCH_PATH, null, null);
                    
                    // ensure the button is sensitive; it might be the first plug loaded
                    if (!@extern) {
                        navigation_button.set_sensitive(true);
                        navigation_button.set_icon_name ("go-home");
                        current_plug["title"] = title;
                        current_plug["executable"] = executable;
                        switch_to_socket ();
                        main_window.title = @"$APP_TITLE - $title";
                    }
                } catch {  warning(_("Failed to launch plug: title %s | executable %s"), title, executable); }
            } else {
                navigation_button.set_sensitive(true);
                navigation_button.set_icon_name ("go-home");
            }
            
            if (@extern) {
                switch_to_icons ();
            }
        }

        // Change Switchboard title back to "Switchboard"
        void reset_title () {
            main_window.title = APP_TITLE;
        }

        // Handles clicking the navigation button
        void handle_navigation_button_clicked () {
            string icon_name = navigation_button.get_icon_name ();
            if (icon_name == "go-home") {
                switch_to_icons();
                navigation_button.set_icon_name ("go-previous");
            }
            else {
                load_plug (current_plug["title"], current_plug["executable"], current_plug["extern"] == "1");
                navigation_button.set_icon_name ("go-home");
            }
        }

        // Switches to the socket view
        void switch_to_socket () {

            socket_shown = true;
            search_box.sensitive = false;

            category_view.hide ();
            socket.hide ();
            loading.show_all ();
        }
        
        // Switches back to the icons
        bool switch_to_icons () {
            socket.hide ();
            loading.hide ();
            category_view.show ();
            
            socket_shown = false;

            // Reset state
            reset_title ();
            search_box.set_text("");
            search_box.sensitive = count_plugs() > 0;
            progress_label.set_text("");
            progress_bar.fraction = 0.0;
            progress_toolitem.visible = false;
            
            plug_closed ();
            
            return true;
        }

        // Loads in all of the plugs
        // Returns true if any were found,
        // false if none were.
        bool enumerate_plugs (string plug_root_dir) {

            // <keyfile's absolute path, keyfile's directory>
            List<string> keyfiles = find_plugs (plug_root_dir);
            if (keyfiles.length() == 0) {
                return false;
            } else {
                foreach (string keyfile in keyfiles) {
                    KeyFile kf = new KeyFile();

                    string head = File.new_for_path(keyfile).get_basename();
                    string parent = File.new_for_path(keyfile).get_parent().get_path();

                    Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                    try { kf.load_from_file(keyfile, KeyFileFlags.NONE);
                    } catch (Error e) { warning("Couldn't load this keyfile, %s (path: %s)", e.message, keyfile); }
                    plug["id"] = kf.get_start_group();
                    try {
                        var exec = kf.get_string (head, "exec");
                        //if a path starts with a double slash, we take it as an absolute path
                        if (exec.substring (0, 2) == "//") {
                            exec = exec.substring (1);
                            plug["extern"] = "1";
                        } else {
                            exec = Path.build_filename(parent, exec);
                            plug["extern"] = "0";
                        }
                        
                        plug["exec"] = exec;
                    } catch (Error e) { warning("Couldn't read exec field in file %s, %s", keyfile, e.message); }
                    try { plug["icon"] = kf.get_string (head, "icon");
                    } catch (Error e) { warning("Couldn't read icon field in file %s, %s", keyfile, e.message); }
                    try {
                        plug["title"] = kf.get_locale_string (head, "title");
                        string? textdomain = null;
                        foreach (var domain_key in SUPPORTED_GETTEXT_DOMAINS_KEYS) {
                            if (kf.has_key (head, domain_key)) {
                                textdomain = kf.get_string (head, domain_key);
                                break;
                            }
                        }
                        if (textdomain != null)
                            plug["title"] = GLib.dgettext (textdomain, plug["title"]).dup ();
                    } catch (Error e) { warning("Couldn't read title field in file %s, %s", keyfile, e.message); }
                    try { plug["category"] = kf.get_string (head, "category");
                    } catch {
                        plug["category"] = "other";
                    }
                    category_view.add_plug (plug);
                    plugs += plug;
                }
                return true;
            }
        }

        // Checks if the file is a .plug file
        bool is_plug_file (string filename) {
            return (filename.down().has_suffix(".plug"));
        }

        // Find all .plug files
        List<string> find_plugs (string path, List<string>? keyfiles_list = null) {
            List<string>? keyfiles;
            if(keyfiles_list == null) {
                keyfiles = new List<string> ();
            } else {
                keyfiles = new List<string> ();
                foreach(var keyfile in keyfiles_list) {
                    keyfiles.append(keyfile);
                }
            }
            
            var directory = File.new_for_path (path);
            if (!directory.query_exists ()) {
                return null;
            }
            try {
                var enumerator = directory.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    string file_path = Path.build_filename(path, file_info.get_name());
                    if (file_info.get_file_type() == GLib.FileType.REGULAR && 
                        is_plug_file(file_info.get_name())) {
                        keyfiles.append(file_path);
                    } else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
                        keyfiles = find_plugs(file_path, keyfiles);
                    }
                }
            } catch { warning(_(@"Unable to iterate over enumerated plug directory \"$path\"'s contents")); }
            
            return keyfiles;
        }

        // Counts how many plugs exist at the moment
        int count_plugs () {

            uint count = 0;
            foreach (string place in plug_places)
                count += find_plugs (place).length ();
            return (int) count;
        }

        /*
            D-Bus ONLY methods
        */

        public int get_socket_wid () {

            return ((int) socket.get_id ());
        }

        public signal void plug_closed ();

        public void progress_bar_set_visible (bool visibility) {

            progress_toolitem.set_visible(visibility);
        }

        public void progress_bar_set_text (string text) {

            progress_label.set_text(text);
        }

        public void progress_bar_set_fraction (double fraction) {

            progress_bar.fraction = fraction;
        }

        public void progress_bar_pulse () {

            progress_bar.pulse();
        }

        public signal void search_box_activated ();

        public signal void search_box_text_changed ();

        public void search_box_set_sensitive (bool sensitivity) {
            search_box.set_sensitive (sensitivity);
        }

        public void search_box_set_text (string text) {

            plug_closed();
            search_box.set_text (text);
        }

        public string search_box_get_text () {

            return search_box.get_text ();
        }

        /*
           End D-Bus ONLY methods
        */

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
            search_box.activate.connect(() => search_box_activated());
            search_box.changed.connect(() => {
                category_view.filter_plugs(search_box.get_text (), this);
                search_box_text_changed();
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
            navigation_button = new Gtk.ToolButton (null,null);
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
        
        public override void activate () {
            // If app is already running, present the current window.
            if (get_windows () != null) {
                get_windows ().data.present ();
                return;
            }

            build ();
        }

        // Updates items in quicklist menu using the Unity quicklist api.
        void update_libunity_quicklist () {
            // Fetch launcher
            var launcher = Unity.LauncherEntry.get_for_desktop_id (app_launcher);
            var quicklist = new Dbusmenu.Menuitem ();

            // Add menuitems for every category.
            for (int i = 0; i < category_view.category_names.length; i++) {
                // Create menuitem for this category
                var category_item = new Dbusmenu.Menuitem ();
                var category_name = category_view.category_names[i];
                category_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _(category_name));

                // Loop through every plug and add a quicklist item
                var category_id = category_view.category_ids[i];
                var category_store = category_view.category_store[category_id];
                category_store.foreach ((model, path, iter) => {
                    string title, exec, @extern;
                    category_store.get (iter, 1, out title, 2, out exec, 4, out @extern);

                    var item = new Dbusmenu.Menuitem ();
                    item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, title);

                    // When item is clicked, open corresponding plug
                    item.item_activated.connect (() => {
                        load_plug (title, exec, @extern == "1");
                        activate ();
                    });

                    // Add item to correct category
                    category_item.child_append (item);

                    return false;
                });

                quicklist.child_append (category_item);
            }

            launcher.quicklist = quicklist;
        }
    }

    static const OptionEntry[] entries = {
            { "open-plug", 'o', 0, OptionArg.STRING, ref plug_to_open, N_("Open a plug"), "PLUG_NAME" },
            { null }
    };

    public static int main (string[] args) {

        var logger = new Granite.Services.Logger ();
        logger.initialize(APP_TITLE);
        logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        message(_(@"Welcome to $APP_TITLE"));
        message(_(@"Version: $VERSION"));
        message(_("Report any issues/bugs you mind find to lp:switchboard"));
        
        Gtk.init (ref args);
        
        var context = new OptionContext("");
        context.add_main_entries(entries, "switchboard ");
        context.add_group(Gtk.get_option_group(true));
        try {
            context.parse(ref args);
        } catch(Error e) { warning (e.message); }
        
        // In the future, the plug_root_dir should be overridable by CLI flags.
        var switchboard_app = new SwitchboardApp ();
        
        GLib.Bus.own_name (BusType.SESSION, "org.elementary.switchboard",
                BusNameOwnerFlags.NONE,
                (conn) => { 
                    try {
                        conn.register_object("/org/elementary/switchboard", switchboard_app);
                    } catch (IOError e) { warning (e.message); }
                },
                () => {},
                () => {logger.notification(_("Switchboard already running. Exiting..")); Process.exit(1);});
        
        return switchboard_app.run (args);
    }
}
