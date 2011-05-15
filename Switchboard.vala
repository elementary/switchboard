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
using ElementaryWidgets;

namespace SwitchBoard {
    public const string version = "0.5 alpha";
    public const string errdomain = "switchboard";
    public const string plug_base_dir = "/usr/share/plugs/";
    public const string app_title = "Switchboard";
    
    [DBus (name = "org.elementary.switchboard")]
    public class SettingsApp : Window {
       
        /* Toolbar widgets */
        private AppMenu app_menu;
        private ProgressBar progress_bar;
        private Label progress_label;
        private ElementaryEntry find_entry;
        private Toolbar toolbar;
        private ToolButton navigation_button;
        public ToolItem progress_toolitem;
        private ToolItem lspace = new ToolItem ();
        private ToolItem rspace = new ToolItem ();
        
        /* Content Area widgets */
        private Gtk.Socket socket;
        private VBox vbox;
        private CategoryView category_view = new CategoryView({ "Personal", "Hardware", "Network and Wireless", "System" });
        
        /* Plugging Data */
        private TreeIter selected_plug;
        private bool socket_shown;
        private Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();

        public SettingsApp () {
            /* Setup window */
            this.height_request = 500;
            this.width_request = 800;
            this.position = Gtk.WindowPosition.CENTER;
            this.title = SwitchBoard.app_title;
            this.destroy.connect(()=> shutdown());
            
            /* Setup Plug Socket */
            this.socket = new Gtk.Socket ();
            this.socket.plug_added.connect(this.switch_to_socket);
            this.socket.plug_removed.connect(this.switch_to_icons);
            this.socket.hide();
            
            /* Defaults for current plug */
            this.current_plug["title"] = "";
            this.current_plug["executable"] = "";
            
            /* Setup toolbar */
            setup_toolbar ();
            
            /* Wire up interface */
            this.category_view.plug_selected.connect((view, store) => load_plug(view, store));
            this.vbox = new VBox (false, 0);
            this.vbox.pack_start (this.toolbar, false, false);
            this.vbox.pack_start (this.socket, false, false);
            this.vbox.pack_end (this.category_view, true, true);  
            this.add (this.vbox);
            
            this.enumerate_plugs ();
            this.show_all ();
        }
        
        public int get_socket_wid() {
            return ((int) this.socket.get_id ());
        }
        
        private void shutdown() {
    
            plug_closed();
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
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                "Selected plug: title %s | executable %s", title.get_string(),
                 executable.get_string());
                /* Launch plug's executable */
                if (executable.get_string() != this.current_plug["title"]) {
                    try {
                        if (this.current_plug["title"] != "") {
                            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                            "Exiting plug from SwitchBoard controller..");
                            plug_closed();
                        }
                        GLib.Process.spawn_command_line_async (plug_base_dir + executable.get_string());
                        this.current_plug["title"] = title.get_string();
                        this.current_plug["executable"] = executable.get_string();
                        // ensure the button is sensitive; it might be the first plug loaded
                        this.navigation_button.set_sensitive(true);
                        this.navigation_button.stock_id = Gtk.Stock.HOME;
                    } catch {
                        GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                        "Failed to launch plug: title %s | executable %s", 
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
            this.title = "Switchboard - " + plug_title;
        }

        // Change Switchboard title back to "Switchboard"
        private void reset_title () {
            this.title = "Switchboard";
        }
        
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

        // Switch to the socket view
        private void switch_to_socket() {
            this.vbox.set_child_packing(this.socket, true, true, 0, PackType.END);
            this.category_view.hide();
            this.socket.show();
            this.load_plug_title (this.current_plug["title"]);
            this.socket_shown = true;
        }
        
        // Switch back to the icons
        private bool switch_to_icons() {
            this.vbox.set_child_packing(this.socket, false, false, 0, PackType.END);
            this.socket.hide ();
            this.category_view.show();
            this.reset_title ();
            this.socket_shown = false;
            return true;
        }
        
        private void enumerate_plugs () {
            Gee.ArrayList<string> keyfiles = find_plugs (SwitchBoard.plug_base_dir);
            foreach (string keyfile in keyfiles) {
                stdout.printf("%s\n", keyfile);
                KeyFile kf = new KeyFile();
                string[] splits = Regex.split_simple("/", keyfile);
                string head = splits[splits.length-1];
                Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(keyfile, KeyFileFlags.NONE);
                } catch {}
                try { plug["exec"] = kf.get_string (head, "exec");
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
        
        bool is_plug_file (string filename) {
            return (filename.down().has_suffix(".plug"));
        }
        
        // Find all .plug files
        private Gee.ArrayList<string> find_plugs (string in_path) {
            string path = in_path;
            if (path[-1] != '/') {
                path += "/";
            }
	        Gee.ArrayList<string> keyfiles = new Gee.ArrayList<string> ();
            var directory = File.new_for_path (path);
            try {
		        var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
	            FileInfo file_info;
		        while ((file_info = enumerator.next_file ()) != null) {
		            string? file_name = (string) file_info.get_name ();
                    if (file_info.get_file_type() == GLib.FileType.REGULAR
                        && is_plug_file(file_name)) {
			            keyfiles.add(path+file_name);
		            } else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
			            string file_path = path + file_info.get_name();
				        var sub_plugs = find_plugs(file_path);
                        foreach (var subplug in sub_plugs) {
                            keyfiles.add(subplug);
                        }
                    }
		        }
		    } catch {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                "Unable to interate over enumerated plug directory contents");
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

        public void search_box_set_sensitive (bool sensitivity) {
            this.find_entry.set_sensitive (sensitivity);
        }

        public void search_box_set_text (string text) {
            this.find_entry.set_text (text);
        }

        // end D-Bus ONLY methods

        private void setup_toolbar () {
        
            // Global toolbar widgets
            this.toolbar = new Toolbar ();
            var menu = new Menu ();
            this.app_menu = new AppMenu (this, menu, "Switchboard", 
                                        "switchboard", 
                                        "http://launchpad.net/switchboard",
                                        "0.5 alpha", 
                                        "Copyright (C) 2011 Avi Romanoff",
                                        {"Avi Romanoff <aviromanoff@gmail.com>"},
                                        "preferences-desktop");
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
            this.find_entry = new ElementarySearchEntry ("Type to search ...");
            this.find_entry.activate.connect(() => search_box_activated());
            var find_toolitem = new ToolItem ();
            find_toolitem.add (this.find_entry);
            
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
        }
    }

    private void on_bus_aquired (DBusConnection conn) {
        SettingsApp settings_app = new SettingsApp ();
        settings_app.progress_toolitem.hide();
        try {
            conn.register_object ("/org/elementary/switchboard", settings_app);
        } catch (IOError e) {
        }
    }
    
    public static int main (string[] args) {
        GLib.Log.set_default_handler(Log.log_handler);
        Gtk.init (ref args);
        
        GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_INFO, 
                "Welcome to Switchboard");
        GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_INFO, 
                "Version: %s", SwitchBoard.version);
        GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_INFO, 
                "Report any issues/bugs you might find to lp:switchboard");
        
        Bus.own_name (BusType.SESSION, "org.elementary.switchboard", 
                BusNameOwnerFlags.NONE,
                on_bus_aquired,
                () => {},
                () => stderr.printf ("Could not aquire name\n"));
        
        Gtk.main ();
        return 0;
    }
}
