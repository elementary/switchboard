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

namespace Switchboard {

    [DBus (name = "org.elementary.switchboard")]
    public class SwitchboardApp : Gtk.Window {

        // Chrome widgets
        ElementaryWidgets.AppMenu app_menu;
        Gtk.ProgressBar progress_bar;
        Gtk.Label progress_label;
        Granite.Widgets.SearchBar search_bar;
        Gtk.Toolbar toolbar;
        Gtk.ToolButton navigation_button;
        // Public so we can hide it after show_all()
        public Gtk.ToolItem progress_toolitem;
        // These two wrap the progress bar
        Gtk.ToolItem lspace = new Gtk.ToolItem ();
        Gtk.ToolItem rspace = new Gtk.ToolItem ();

        // Content area widgets
        Gtk.Socket socket;
        Gtk.VBox vbox;
        Switchboard.CategoryView category_view = new Switchboard.CategoryView();

        // Plug data
        Gtk.TreeIter selected_plug;
        bool socket_shown;
        Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();

        public SwitchboardApp (string plug_root_dir) {
            
            // Set up defaults
            title = APP_TITLE;

            // Set up window
            height_request = 500;
            width_request = 800;
            window_position = Gtk.WindowPosition.CENTER;
            destroy.connect(()=> shutdown());
            setup_toolbar ();

            // Set up socket
            socket = new Gtk.Socket ();
            socket.plug_added.connect(switch_to_socket);
            socket.plug_removed.connect(switch_to_icons);
            socket.hide();

            // ??? Why?
            current_plug["title"] = "";
            current_plug["executable"] = "";

            // Set up UI
            category_view.plug_selected.connect((view, store) => load_plug(view, store));
            vbox = new Gtk.VBox (false, 0);
            vbox.pack_start (toolbar, false, false);
            vbox.pack_start (socket, false, false);
            vbox.pack_end (category_view, true, true);
            add (vbox);
            vbox.show();
            category_view.show();

            //enumerate_plugs ("/usr/share/plugs/");
            enumerate_plugs ("/usr/lib/plugs/");
            show();
        }

        void shutdown() {

            plug_closed();
            // What's this for? Smells like a bad idea.
            while(Gtk.events_pending ()) {
                Gtk.main_iteration();
            }
            Gtk.main_quit();
        }

        void load_plug(Gtk.IconView plug_view, Gtk.ListStore store) 
        {

            var selected = plug_view.get_selected_items ();
            if(selected.length() == 1) {
                GLib.Value title;
                GLib.Value executable;
                var item = selected.nth_data(0);
                store.get_iter(out selected_plug, item);
                store.get_value (selected_plug, 0, out title);
                store.get_value (selected_plug, 2, out executable);
                debug(_("Selected plug: title %s | executable %s"), title.get_string(), executable.get_string());
                // Launch plug's executable
                if (executable.get_string() != current_plug["title"]) {
                    try {
                        // The plug is already selected
                        if (current_plug["title"] != title.get_string()) {
                            debug(_("Exiting plug \"%s\" from Switchboard controller.."), current_plug["title"]);
                            plug_closed();
                            GLib.Process.spawn_command_line_async (executable.get_string());
                            current_plug["title"] = title.get_string();
                            current_plug["executable"] = executable.get_string();
                            // ensure the button is sensitive; it might be the first plug loaded
                            navigation_button.set_sensitive(true);
                            navigation_button.stock_id = Gtk.Stock.HOME;
                        } else {
                            switch_to_socket();
                        }
                    } catch {
                        warning(_("Failed to launch plug: title %s | executable %s"), title.get_string(), executable.get_string());
                    }
                }
                else {
                    switch_to_socket();
                    navigation_button.set_sensitive(true);
                    navigation_button.stock_id = Gtk.Stock.HOME;
                }
                /* Clear selection again */
                plug_view.unselect_path(item);
            }
        }

        // Change Switchboard title to "Switchboard - PlugName"
        void load_plug_title (string plug_title) {
            title = APP_TITLE+ " - " + plug_title;
        }

        // Change Switchboard title back to "Switchboard"
        void reset_title () {
            title = APP_TITLE;
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
            category_view.hide();
            socket.show();
            load_plug_title (current_plug["title"]);
            socket_shown = true;
        }

        // Switches back to the icons
        bool switch_to_icons() {
            vbox.set_child_packing(socket, false, false, 0, Gtk.PackType.END);
            socket.hide ();
            category_view.show();
            reset_title ();
            socket_shown = false;
            return true;
        }

        // Loads in all of the plugs
        void enumerate_plugs (string plug_root_dir) {
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
                category_view.add_plug (plug);
            }
        }

        // Checks if the file is a .plug file
        bool is_plug_file (string filename) {
            return (filename.down().has_suffix(".plug"));
        }

        // Find all .plug files
        Gee.HashMap<string, string> find_plugs (string in_path) {
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
                warning(_(@"Unable to iterate over enumerated plug directory \"$in_path\"'s contents"));
            }
            return keyfiles;
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
            search_bar.set_sensitive (sensitivity);
        }

        public void search_box_set_text (string text) {
            search_bar.set_text (text);
        }

        public string search_box_get_text () {
            return search_bar.get_text ();
        }

        // end D-Bus ONLY methods

        // Sets up the toolbar for the Switchboard app
        void setup_toolbar () {
            // Global toolbar widgets
            toolbar = new Gtk.Toolbar ();
            var menu = new Gtk.Menu ();
            app_menu = new ElementaryWidgets.AppMenu (this, menu,
                                        APP_TITLE,
                                        ERRDOMAIN,
                                        WEBSITE,
                                        VERSION,
                                        COPYRIGHT,
                                        AUTHORS,
                                        LICENSE,
                                        APP_ICON);
            // Spacing
            lspace.set_expand (true);
            rspace.set_expand (true);

            // Progressbar
            var progress_vbox = new Gtk.VBox (true, 0);
            progress_label = new Gtk.Label("");
            progress_label.set_use_markup(true);
            progress_bar = new Gtk.ProgressBar ();
            progress_toolitem = new Gtk.ToolItem ();
            progress_vbox.pack_start (progress_label, true, false, 0);
            progress_vbox.pack_end (progress_bar, false, false, 0);
            progress_toolitem.add (progress_vbox);
            progress_toolitem.set_expand (true);

            // Searchbar
            search_bar = new Granite.Widgets.SearchBar (_("Type to search ..."));
            search_bar.activate.connect(() => search_box_activated());
            search_bar.changed.connect(() => search_box_text_changed());
            var find_toolitem = new Gtk.ToolItem ();
            find_toolitem.add (search_bar);

            // Nav button
            navigation_button = new Gtk.ToolButton.from_stock(Gtk.Stock.GO_BACK);
            navigation_button.clicked.connect (handle_navigation_button_clicked);
            navigation_button.set_sensitive (false);

            // Add everything to the toolbar
            toolbar.insert (navigation_button, 0);
            toolbar.insert (lspace, 1);
            toolbar.insert (progress_toolitem, 2);
            toolbar.insert (rspace, 3);
            toolbar.insert (find_toolitem, 4);
            toolbar.insert (app_menu, 5);
            toolbar.show_all();
        }
    }

    // Handles a successful connection to D-Bus and launches the app
    void on_bus_aquired (DBusConnection conn) {
        // In the future, the plug_root_dir should be overridable by CLI flags.
        SwitchboardApp switchboard_app = new SwitchboardApp ("/usr/share/plugs/");
        switchboard_app.progress_toolitem.hide();
        try {
            conn.register_object ("/org/elementary/switchboard", switchboard_app);
        } catch (IOError e) {
        }
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
                on_bus_aquired,
                () => {},
                () => {logger.notification(_("Switchboard already running. Exiting..")); Process.exit(1);});

        Gtk.main ();
        return 0;
    }
}

