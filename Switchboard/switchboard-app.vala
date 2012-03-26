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
            program_name = APP_TITLE;
            app_years = "2011-2012";

            build_version = VERSION;
            app_icon = APP_ICON;
            main_url = WEBSITE;
            about_authors = AUTHORS;

            about_comments = COPYRIGHT;
            about_license_type = Gtk.License.GPL_3_0;
        }

        // Chrome widgets
        Granite.Widgets.AppMenu app_menu;
        Gtk.ProgressBar progress_bar;
        Gtk.Label progress_label;
        Gtk.Entry search_box;
        Gtk.Toolbar toolbar;
        Gtk.ToolButton navigation_button;
        // Public so we can hide it after show_all()
        public Gtk.ToolItem progress_toolitem;
        // These two wrap the progress bar
        Gtk.ToolItem lspace = new Gtk.ToolItem ();
        Gtk.ToolItem rspace = new Gtk.ToolItem ();
        
        Gtk.Window main_window;

        // Content area widgets
        Gtk.Socket socket;
        Gtk.VBox vbox;
        Switchboard.CategoryView category_view = new Switchboard.CategoryView();
        Gtk.ScrolledWindow scrolled;
        Gtk.Viewport viewport;

        // Plug data
        bool socket_shown;
        Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();
        Gee.HashMap<string, string>[] plugs;

        string[] plug_places = {"/usr/share/plugs/", "/usr/lib/plugs/", "/usr/local/share/plugs/", "/usr/local/lib/plugs/"};
        string search_box_buffer = "";    

        public SwitchboardApp () {
            
            main_window = new Gtk.Window();

            // Set up defaults
            main_window.title = APP_TITLE;

            // Set up window
            main_window.height_request = 500;
            main_window.width_request = 800;
            main_window.window_position = Gtk.WindowPosition.CENTER;
            main_window.destroy.connect(()=> shutdown());
            setup_toolbar ();

            // Set up socket
            socket = new Gtk.Socket ();
            socket.plug_removed.connect(switch_to_icons);
            socket.hide();

            // ??? Why?
            current_plug["title"] = "";
            current_plug["executable"] = "";

            // Set up UI
            category_view.plug_selected.connect((title, executable) => load_plug (title, executable));
            vbox = new Gtk.VBox (false, 0);
            vbox.pack_start (toolbar, false, false);
            vbox.pack_start (socket, false, false);

            scrolled = new Gtk.ScrolledWindow (null, null);
            viewport = new Gtk.Viewport (null, null);
            viewport.add (category_view);
            scrolled.add (viewport);
            vbox.pack_end (scrolled, true, true);

            main_window.add (vbox);
            vbox.show ();
            category_view.show ();
            scrolled.show ();
            viewport.show ();

            foreach (string place in plug_places)
                enumerate_plugs (place);

            main_window.show ();
            
            bool found = false;
            if (plug_to_open != null) {
                foreach (var plug in plugs)
                    if (plug["title"] == plug_to_open) {
                        load_plug (plug["title"], plug["exec"]);
                        found = true;
                    }
                if (!found)
                    critical ("Couldn't find %s between the loaded plugs.", plug_to_open);
            }
        }

        void shutdown() {

            plug_closed();
            // What's this for? Smells like a bad idea.
//            while(Gtk.events_pending ()) {
//                Gtk.main_iteration();
//            }
            Gtk.main_quit();
        }

        public void load_plug (string title, string executable) {
            debug("Selected plug: title %s | executable %s", title, executable);
            debug("Current plug: %s", current_plug["title"]);
            // Launch plug's executable
            if (current_plug["title"] != title) {
                try {
                    // The plug is already selected
                    debug(_("Exiting plug \"%s\" from Switchboard controller.."), current_plug["title"]);
                    plug_closed();
                    var cmd_exploded = executable.split(" ");
                    string working_directory = File.new_for_path(cmd_exploded[0]).get_parent().get_path();
                    GLib.Process.spawn_async(working_directory, cmd_exploded, null, SpawnFlags.SEARCH_PATH, null, null);
                    current_plug["title"] = title;
                    current_plug["executable"] = executable;
                    // ensure the button is sensitive; it might be the first plug loaded
                    navigation_button.set_sensitive(true);
                    navigation_button.stock_id = Gtk.Stock.HOME;
                    switch_to_socket ();
                } catch {
                    warning(_("Failed to launch plug: title %s | executable %s"), title, executable);
                }
            }
            else {
                switch_to_socket ();
                navigation_button.set_sensitive(true);
                navigation_button.stock_id = Gtk.Stock.HOME;
            }
        }

        // Change Switchboard title to "Switchboard - PlugName"
        void load_plug_title (string plug_title) {

            main_window.title = @"$APP_TITLE - $plug_title";
        }

        // Change Switchboard title back to "Switchboard"
        void reset_title () {
            main_window.title = APP_TITLE;
        }

        // Handles clicking the navigation button
        void handle_navigation_button_clicked () {

            if (navigation_button.stock_id == Gtk.Stock.HOME) {
                switch_to_icons();
                navigation_button.stock_id = Gtk.Stock.GO_BACK;
            }
            else {
                switch_to_socket();
                navigation_button.stock_id = Gtk.Stock.HOME;
            }
        }

        // Switches to the socket view
        void switch_to_socket() {

            vbox.set_child_packing(socket, true, true, 0, Gtk.PackType.END);
            scrolled.hide();
            socket.show();
            load_plug_title (current_plug["title"]);
            socket_shown = true;
            switch_search_box(false);
        }

        // Switches back to the icons
        bool switch_to_icons() {

            vbox.set_child_packing(socket, false, false, 0, Gtk.PackType.END);
            socket.hide ();
            scrolled.show();
            reset_title ();
            socket_shown = false;
            switch_search_box((count_plugs () > 0));
            return true;
        }

        // Gracefully switches search_box's sensitivity
        void switch_search_box(bool sensitive) {

            if (sensitive) {
                search_box.set_text(search_box_buffer);
            } else {
                search_box_buffer = search_box.get_text();
                search_box.set_text("");      
            }

            search_box.sensitive = sensitive;
        }

        // Loads in all of the plugs
        void enumerate_plugs (string plug_root_dir) {

            // <keyfile's absolute path, keyfile's directory>
            List<string> keyfiles = find_plugs (plug_root_dir);
            foreach (string keyfile in keyfiles) {
                KeyFile kf = new KeyFile();

                string head = File.new_for_path(keyfile).get_basename();
                string parent = File.new_for_path(keyfile).get_parent().get_path();

                Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(keyfile, KeyFileFlags.NONE);
                } catch (Error e) { warning("Couldn't load this keyfile, %s (path: %s)", e.message, keyfile); }
                try { plug["exec"] = Path.build_filename(parent, kf.get_string (head, "exec"));
                } catch (Error e) { warning("Couldn't read exec field in file %s, %s", keyfile, e.message); }
                try { plug["icon"] = kf.get_string (head, "icon");
                } catch (Error e) { warning("Couldn't read icon field in file %s, %s", keyfile, e.message); }
                try { plug["title"] = kf.get_locale_string (head, "title");
                } catch (Error e) { warning("Couldn't read title field in file %s, %s", keyfile, e.message); }
                try { plug["category"] = kf.get_string (head, "category");
                } catch {
                    plug["category"] = "other";
                }
                category_view.add_plug (plug);
                plugs += plug;
            }
        }

        // Checks if the file is a .plug file
        bool is_plug_file (string filename) {

            return (filename.down().has_suffix(".plug"));
        }

        // Find all .plug files
        List<string> find_plugs (string path, List<string>? keyfiles_list = null)
        {
            List<string>? keyfiles;
            if(keyfiles_list == null)
            {
                keyfiles = new List<string> ();
            }
            else
            {
                keyfiles = new List<string> ();
                foreach(var keyfile in keyfiles_list) 
                {
                keyfiles.append(keyfile);
                }
            }
            var directory = File.new_for_path (path);
            try
            {
                var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null)
                {
                    string file_path = Path.build_filename(path, file_info.get_name());
                    if (file_info.get_file_type() == GLib.FileType.REGULAR && is_plug_file(file_info.get_name()))
                    {
                        keyfiles.append(file_path);
                    }
                    else if(file_info.get_file_type() == GLib.FileType.DIRECTORY)
                    {
                        keyfiles = find_plugs(file_path, keyfiles);
                    }
                }
            }
            catch
            {
                warning(_(@"Unable to iterate over enumerated plug directory \"$path\"'s contents"));
            }
            return keyfiles;
        }

        // Counts how many plugs exist at the moment
        int count_plugs () {

            uint count = 0;
            foreach (string place in plug_places)
                count += find_plugs (place).length ();
            return (int) count;
        }

        // D-Bus ONLY methods

        public int get_socket_wid() {

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

        // end D-Bus ONLY methods

        // Sets up the toolbar for the Switchboard app
        void setup_toolbar () {

            // Global toolbar widgets
            toolbar = new Gtk.Toolbar ();
            toolbar.get_style_context ().add_class ("primary-toolbar");

            var menu = new Gtk.Menu ();
            app_menu = create_appmenu(menu);
            // Spacing
            lspace.set_expand(true);
            rspace.set_expand(true);

            // Progressbar
            var progress_vbox = new Gtk.VBox (true, 0);
            progress_label = new Gtk.Label ("");
            progress_label.set_use_markup(true);
            progress_bar = new Gtk.ProgressBar ();
            progress_toolitem = new Gtk.ToolItem ();
            progress_vbox.pack_start(progress_label, true, false, 0);
            progress_vbox.pack_end(progress_bar, false, false, 0);
            progress_toolitem.add(progress_vbox);
            progress_toolitem.set_expand(true);

            // Searchbar
            search_box = new Gtk.Entry ();
            search_box.placeholder_text = _("Search Plugs");
            search_box.primary_icon_stock = "gtk-find";
            search_box.activate.connect(() => search_box_activated());
            search_box.changed.connect(() => {
                category_view.filter_plugs(search_box.get_text ());
                search_box_text_changed();
            });
            search_box.sensitive = (count_plugs () > 0);
            var find_toolitem = new Gtk.ToolItem ();
            find_toolitem.add(search_box);

            // Nav button
            navigation_button = new Gtk.ToolButton.from_stock(Gtk.Stock.GO_BACK);
            navigation_button.clicked.connect (handle_navigation_button_clicked);
            navigation_button.set_sensitive(false);

            // Add everything to the toolbar
            toolbar.insert(navigation_button, 0);
            toolbar.insert(lspace, 1);
            toolbar.insert(progress_toolitem, 2);
            toolbar.insert(rspace, 3);
            toolbar.insert(find_toolitem, 4);
            toolbar.insert(app_menu, 5);
            toolbar.show_all();
        }
    }
    
    static const OptionEntry[] entries = {
            { "open-plug", 'o', 0, OptionArg.STRING, ref plug_to_open, "Open a plug", "PLUG_PATH" },
            { null }
    };

    // Handles a successful connection to D-Bus and launches the app
    void on_bus_aquired (DBusConnection conn, string[] args) {
    
        var context = new OptionContext("Plug");
        context.add_main_entries(entries, "switchboard ");
        context.add_group(Gtk.get_option_group(true));
        try {
            context.parse(ref args);
        } catch(Error e) {
            print(e.message + "\n");
        }

        // In the future, the plug_root_dir should be overridable by CLI flags.
        SwitchboardApp switchboard_app = new SwitchboardApp ();
        switchboard_app.progress_toolitem.hide();
        try {
            conn.register_object("/org/elementary/switchboard", switchboard_app);
        } catch (IOError e) {
        }
        
        switchboard_app.run (args);
    }

    static int main (string[] args) {

        var logger = new Granite.Services.Logger ();
        logger.initialize(APP_TITLE);
        logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        message(_(@"Welcome to $APP_TITLE"));
        message(_(@"Version: $VERSION"));
        message(_("Report any issues/bugs you mind find to lp:switchboard"));

        Gtk.init (ref args);
        Bus.own_name (BusType.SESSION, "org.elementary.switchboard",
                BusNameOwnerFlags.NONE,
                (conn) => {on_bus_aquired (conn, args);},
                () => {},
                () => {logger.notification(_("Switchboard already running. Exiting..")); Process.exit(1);});

        Gtk.main ();
        return 0;
    }
}
