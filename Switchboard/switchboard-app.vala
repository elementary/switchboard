/***
BEGIN LICENSE
Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
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

using Gtk;

namespace Switchboard {

    [DBus (name = "org.elementary.switchboard")]
    public class SwitchboardApp : Window {

        // Default
        private string plug_root_dir;

        // Chrome widgets
        private ElementaryWidgets.AppMenu app_menu;
        private ProgressBar progress_bar;
        private Label progress_label;
        private Granite.Widgets.SearchBar search_bar;
        private Toolbar toolbar;
        private ToolButton navigation_button;
        public ToolItem progress_toolitem;
        // These two wrap the progress bar
        private ToolItem lspace = new ToolItem ();
        private ToolItem rspace = new ToolItem ();

        // Content area widgets
        private Gtk.Socket socket;
        private VBox vbox;
        private CategoryView category_view = new CategoryView();

        // Plug data
        private TreeIter selected_plug;
        private bool socket_shown;
        private Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();

        public SwitchboardApp (string plug_root_dir) {
            
            // Set up defaults
            this.plug_root_dir = "/usr/share/plugs/";
            this.title = APP_TITLE;

            // Set up window
            this.height_request = 500;
            this.width_request = 800;
            this.window_position = Gtk.WindowPosition.CENTER;
            this.destroy.connect(()=> shutdown());
            setup_toolbar ();

            // Set up socket
            this.socket = new Gtk.Socket ();
            this.socket.plug_added.connect(this.switch_to_socket);
            this.socket.plug_removed.connect(this.switch_to_icons);
            this.socket.hide();

            // ??? Why?
            this.current_plug["title"] = "";
            this.current_plug["executable"] = "";

            // Set up UI
            this.category_view.plug_selected.connect((view, store) => load_plug(view, store));
            this.vbox = new VBox (false, 0);
            this.vbox.pack_start (this.toolbar, false, false);
            this.vbox.pack_start (this.socket, false, false);
            this.vbox.pack_end (this.category_view, true, true);
            this.add (this.vbox);
            this.vbox.show();
            this.category_view.show();

            this.enumerate_plugs ();
            this.show();
        }

        public int get_socket_wid() {
            return ((int) this.socket.get_id ());
        }

        private void shutdown() {
            plug_closed();
            // What's this for? Smells like a bad idea.
            while(events_pending ()) {
                main_iteration();
            }
            Gtk.main_quit();
        }

        private void load_plug(IconView plug_view, ListStore store) {
            var selected = plug_view.get_selected_items ();
            if(selected.length() == 1) {
                GLib.Value title;
                GLib.Value executable;
                var item = selected.nth_data(0);
                store.get_iter(out this.selected_plug, item);
                store.get_value (this.selected_plug, 0, out title);
                store.get_value (this.selected_plug, 2, out executable);
                GLib.log(Switchboard.ERRDOMAIN, LogLevelFlags.LEVEL_DEBUG,
                _("Selected plug: title %s | executable %s"), title.get_string(),
                 executable.get_string());
                // Launch plug's executable
                stdout.printf("Current plug title %s\n", this.current_plug["title"]);
                if (executable.get_string() != this.current_plug["title"]) {
                    try {
                        // The plug is already selected
                        if (this.current_plug["title"] != title.get_string()) {
                            GLib.log(Switchboard.ERRDOMAIN, LogLevelFlags.LEVEL_DEBUG,
                            _("Exiting plug from Switchboard controller.."));
                            plug_closed();
                            GLib.Process.spawn_command_line_async (executable.get_string());
                            this.current_plug["title"] = title.get_string();
                            this.current_plug["executable"] = executable.get_string();
                            // ensure the button is sensitive; it might be the first plug loaded
                            this.navigation_button.set_sensitive(true);
                            this.navigation_button.stock_id = Gtk.Stock.HOME;
                        } else {
                            switch_to_socket();
                        }
                    } catch {
                        GLib.log(Switchboard.ERRDOMAIN, LogLevelFlags.LEVEL_DEBUG,
                        _("Failed to launch plug: title %s | executable %s"),
                        title.get_string(), executable.get_string());
                    }
                }
                else {
                    this.switch_to_socket();
                    this.navigation_button.set_sensitive(true);
                    this.navigation_button.stock_id = Gtk.Stock.HOME;
                }
                /* Clear selection again */
                plug_view.unselect_path(item);
            }
        }

        // Change Switchboard title to "Switchboard - PlugName"
        private void load_plug_title (string plug_title) {
            this.title = APP_TITLE+ " - " + plug_title;
        }

        // Change Switchboard title back to "Switchboard"
        private void reset_title () {
            this.title = APP_TITLE;
        }

        // Handles clicking the navigation button
        private void handle_navigation_button_clicked () {
            if (this.navigation_button.stock_id == Gtk.Stock.HOME) {
                switch_to_icons();
                this.navigation_button.stock_id = Gtk.Stock.GO_BACK;
            }
            else {
                switch_to_socket();
                this.navigation_button.stock_id = Gtk.Stock.HOME;
            }
        }

        // Switches to the socket view
        private void switch_to_socket() {
            this.vbox.set_child_packing(this.socket, true, true, 0, PackType.END);
            this.category_view.hide();
            this.socket.show();
            this.load_plug_title (this.current_plug["title"]);
            this.socket_shown = true;
        }

        // Switches back to the icons
        private bool switch_to_icons() {
            this.vbox.set_child_packing(this.socket, false, false, 0, PackType.END);
            this.socket.hide ();
            this.category_view.show();
            this.reset_title ();
            this.socket_shown = false;
            return true;
        }

        // Loads in all of the plugs
        private void enumerate_plugs () {
            // <keyfile's absolute path, keyfile's directory>
            Gee.HashMap<string, string> keyfiles = find_plugs (plug_root_dir);
            foreach (string keyfile in keyfiles.keys) {
                KeyFile kf = new KeyFile();
                string[] splits = Regex.split_simple("/", keyfile);
                string head = splits[splits.length-1];
                Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(keyfile, KeyFileFlags.NONE);
                } catch {}
                try { plug["exec"] = keyfiles[keyfile]+kf.get_string (head, "exec");
                } catch {}
                try { plug["icon"] = kf.get_string (head, "icon");
                } catch {}
                try { plug["title"] = kf.get_string (head, "title");
                } catch {}
                try { plug["category"] = kf.get_string (head, "category");
                } catch {
                    plug["category"] = "other";
                }
                this.category_view.add_plug (plug);
            }
        }

        // Checks if the file is a .plug file
        bool is_plug_file (string filename) {
            return (filename.down().has_suffix(".plug"));
        }

        // Find all .plug files
        private Gee.HashMap<string, string> find_plugs (string in_path) {
            // Heads up, this needs to be investigated
            string path = in_path;
            if (path[-1] != '/') {
                path += "/";
            }
            Gee.HashMap<string, string> keyfiles = new Gee.HashMap<string, string> ();
            var directory = File.new_for_path (path);
            try {
                var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    string? file_name = (string) file_info.get_name ();
                    if (file_info.get_file_type() == GLib.FileType.REGULAR
                        && is_plug_file(file_name)) {
                        keyfiles[path+file_name] = path;
                    } else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
                        string file_path = path + file_info.get_name();
                        var sub_plugs = find_plugs(file_path);
                        foreach (string subplug in sub_plugs.keys) {
                            keyfiles[subplug] = sub_plugs[subplug];
                        }
                    }
                }
            } catch {
                GLib.log(Switchboard.ERRDOMAIN, LogLevelFlags.LEVEL_DEBUG,
                _("Unable to iterate over enumerated plug directory contents"));
            }
            return keyfiles;
        }

        // D-Bus ONLY methods

        public signal void plug_closed ();

        public void progress_bar_set_visible (bool visibility) {
            this.progress_toolitem.set_visible(visibility);
        }

        public void progress_bar_set_text (string text) {
            this.progress_label.set_text(text);
        }

        public void progress_bar_set_fraction (double fraction) {
            this.progress_bar.fraction = fraction;
        }

        public void progress_bar_pulse () {
            this.progress_bar.pulse();
        }

        public signal void search_box_activated ();

        public signal void search_box_text_changed ();

        public void search_box_set_sensitive (bool sensitivity) {
            this.search_bar.set_sensitive (sensitivity);
        }

        public void search_box_set_text (string text) {
            this.search_bar.set_text (text);
        }

        public string search_box_get_text () {
            return this.search_bar.get_text ();
        }

        // end D-Bus ONLY methods

        // Sets up the toolbar for the Switchboard app
        private void setup_toolbar () {
            // Global toolbar widgets
            this.toolbar = new Toolbar ();
            var menu = new Menu ();
            this.app_menu = new ElementaryWidgets.AppMenu (this, menu,
                                        APP_TITLE,
                                        ERRDOMAIN,
                                        WEBSITE,
                                        VERSION,
                                        COPYRIGHT,
                                        AUTHORS,
                                        LICENSE,
                                        APP_ICON);
            // Spacing
            this.lspace.set_expand (true);
            this.rspace.set_expand (true);

            // Progressbar
            var progress_vbox = new VBox (true, 0);
            this.progress_label = new Label("");
            this.progress_label.set_use_markup(true);
            this.progress_bar = new ProgressBar ();
            this.progress_toolitem = new ToolItem ();
            progress_vbox.pack_start (this.progress_label, true, false, 0);
            progress_vbox.pack_end (this.progress_bar, false, false, 0);
            this.progress_toolitem.add (progress_vbox);
            this.progress_toolitem.set_expand (true);

            // Searchbar
            this.search_bar = new Granite.Widgets.SearchBar (_("Type to search ..."));
            this.search_bar.activate.connect(() => search_box_activated());
            this.search_bar.changed.connect(() => search_box_text_changed());
            var find_toolitem = new ToolItem ();
            find_toolitem.add (this.search_bar);

            // Nav button
            this.navigation_button = new ToolButton.from_stock(Stock.GO_BACK);
            this.navigation_button.clicked.connect (this.handle_navigation_button_clicked);
            this.navigation_button.set_sensitive (false);

            // Add everything to the toolbar
            this.toolbar.insert (navigation_button, 0);
            this.toolbar.insert (this.lspace, 1);
            this.toolbar.insert (this.progress_toolitem, 2);
            this.toolbar.insert (this.rspace, 3);
            this.toolbar.insert (find_toolitem, 4);
            this.toolbar.insert (this.app_menu, 5);
            this.toolbar.show_all();
        }
    }

    // Handles a successful connection to D-Bus and launches the app
    private void on_bus_aquired (DBusConnection conn) {
        // In the future, the plug_root_dir should be overridable by CLI flags.
        SwitchboardApp switchboard_app = new SwitchboardApp ("/usr/share/plugs/");
        switchboard_app.progress_toolitem.hide();
        try {
            conn.register_object ("/org/elementary/switchboard", switchboard_app);
        } catch (IOError e) {
        }
    }

    public static int main (string[] args) {

        var logger = new Granite.Services.Logger ();
        logger.initialize(APP_TITLE);
        logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        message(_(@"Welcome to $APP_TITLE"));
        message(_(@"Version: $VERSION"));
        message(_("Report any issues/bugs you mind find to lp:switchboard"));

        Gtk.init (ref args);
        Bus.own_name (BusType.SESSION, "org.elementary.switchboard",
                BusNameOwnerFlags.NONE,
                on_bus_aquired,
                () => {},
                () => {logger.notification(_("Switchboard already running. Exiting..")); Process.exit(1);});

        Gtk.main ();
        return 0;
    }
}

