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
    public const string version = "0.1 alpha";
    public const string errdomain = "switchboard";
    public const string plug_def_dir = "./plugs/";
    public const string plug_exec_dir = "./plug/";
    public const string app_title = "SwitchBoard";
    
    [DBus (name = "org.elementary.switchplug")]
    public interface PlugController : GLib.Object {
    
        public abstract void exit_plug () throws IOError;
    }
    
    [DBus (name = "org.elementary.switchboard")]
    public class SettingsApp : Window {
       
        /* Toolbar widgets */
        public AppMenu app_menu;
        private Toolbar toolbar;
        private ToolButton navigation_button;
        private ElementaryEntry find_entry;
        private ProgressBar progress_bar;
        ToolItem lspace = new ToolItem ();
        ToolItem rspace = new ToolItem ();
        
        /* Content Area widgets */
        public Gtk.Socket socket;
        private VBox vbox;
        private CategoryView category_view = new CategoryView({ "Personal", "Hardware", "Network and Wireless", "System" });
        
        /* Plugging Data */
        private TreeIter selected_plug;
        private bool socket_shown;
        private Gee.HashMap<string, string> current_plug = new Gee.HashMap<string, string>();
        
        /* D-Bus Controller for Plugs */
        private PlugController plug_controller;

        public SettingsApp () {
            /* Setup window */
            this.height_request = 500;
            this.width_request = 800;
            this.position = Gtk.WindowPosition.CENTER;
            this.title = SwitchBoard.app_title;
            this.destroy.connect(()=> Gtk.main_quit());
            
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
            this.size_allocate.connect(center_progress_bar);
//            this.progress_bar.hide();
            
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
            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Dispatching WID");
            return ((int) this.socket.get_id ());
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
                            this.plug_controller.exit_plug();
                        }
                        GLib.Process.spawn_command_line_async (plug_exec_dir + executable.get_string());
                        try {
                            this.plug_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.switchplug",
                                                                             "/org/elementary/switchplug");
                        } catch (IOError e) {
                            log (SwitchBoard.errdomain, GLib.LogLevelFlags.LEVEL_ERROR, "%s", e.message);
                        }
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
            this.title += " - " + plug_title;
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
            Gee.ArrayList<string> keyfiles = find_plugs ();
            foreach (string keyfile in keyfiles) {
                KeyFile kf = new KeyFile();
                Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(SwitchBoard.plug_def_dir + keyfile, KeyFileFlags.NONE);
                } catch {}
                try { plug["exec"] = kf.get_string (keyfile, "exec");
                } catch {}
                try { plug["icon"] = kf.get_string (keyfile, "icon");
                } catch {}
                try { plug["title"] = kf.get_string (keyfile, "title");
                } catch {}
                try { plug["category"] = kf.get_string (keyfile, "category");
                } catch { 
                    plug["category"] = "other";
                }
                this.category_view.add_plug (plug);
            }
        }
        
        // Find all .plug files
        private Gee.ArrayList<string> find_plugs () {
            var directory = File.new_for_path (SwitchBoard.plug_def_dir);
		    var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);
		    Gee.ArrayList<string> keyfiles = new Gee.ArrayList<string> ();
		    
            try {
		        FileInfo file_info;
			    while ((file_info = enumerator.next_file ()) != null) {
			        string? file_name = (string) file_info.get_name ();
			        if (file_name.length < 5) { continue; }
			        if (file_name[-5:file_name.length] == ".plug" ) {
				    keyfiles.add(file_name);
			        }
			    }
		    } catch {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                "Unable to interate over enumerated plug directory contents");
            }
		    return keyfiles;
        }
        
        private void setup_toolbar () {
        
            // Global toolbar widgets
            this.toolbar = new Toolbar ();
            var menu = new Menu ();
            this.app_menu = new AppMenu.from_stock(Gtk.Stock.PROPERTIES, IconSize.MENU, "Menu", menu);
            
            
            // Appmenu stuff
            // TODO move this into AppMenu proper
            MenuItem go_help = new MenuItem.with_label ("Get Help Online...");
            MenuItem go_translate = new MenuItem.with_label ("Translate This Application...");
            MenuItem go_report = new MenuItem.with_label ("Report a Problem...");
            MenuItem about = new MenuItem.with_label ("About");
            menu.append (go_help);
            menu.append (go_translate);
            menu.append (go_report);
            menu.append (about);
            menu.insert(new SeparatorMenuItem(), 3);
            
            // Connect AppMenu signals
            about.activate.connect (about_dialog);
            go_help.activate.connect (launch_help);
            go_translate.activate.connect (launch_translate);
            go_report.activate.connect (launch_report);
            
            // Spacing
            this.lspace.set_expand (true); 
            this.rspace.set_expand (true); 
            
            
            // Progressbar
            var tvbox = new VBox(true, 0);
            this.progress_bar = new ProgressBar ();
            var progress_toolitem = new ToolItem ();
            tvbox.pack_start(this.progress_bar, false, false, 0);
            progress_toolitem.add (tvbox);
            
            // Searchbar
            this.find_entry = new ElementarySearchEntry ("Type to search ...");
            var find_toolitem = new ToolItem ();
            find_toolitem.add (this.find_entry);
            
            // Nav button
            this.navigation_button = new ToolButton.from_stock(Stock.GO_BACK);
            this.navigation_button.clicked.connect (this.handle_navigation_button_clicked);
            this.navigation_button.set_sensitive (false);
            
            // Add everything to the toolbar
            this.toolbar.insert (navigation_button, 0);
            this.toolbar.insert (this.lspace, 1);
            this.toolbar.insert (progress_toolitem, 2);
            this.toolbar.insert (this.rspace, 3);
            this.toolbar.insert (find_toolitem, 4);
            this.toolbar.insert (this.app_menu, 5);
        }
        
        public void center_progress_bar () {
            // Okay, okay, this is a piece of shit.
            // If you find a better solution, don't
            // hesitate to hit me up. But it's late,
            // and I can't be bothered to bust out
            // the geometry on this one.
            Allocation alloc;
            this.toolbar.get_allocation(out alloc);
            int toolbar_size = alloc.width;
            this.navigation_button.get_allocation(out alloc);
            int nav_size = alloc.width;
            this.progress_bar.get_allocation(out alloc);
            int prog_size = alloc.width;
            this.find_entry.get_allocation(out alloc);
            int search_size = alloc.width;
            this.app_menu.get_allocation(out alloc);
            int appmenu_size = alloc.width;
            // -1 because of the pad between the edge
            // of the toolbar and the window border.
            this.lspace.set_size_request(((toolbar_size/2-nav_size)-prog_size/2)-1, 38);
            this.rspace.set_size_request(((toolbar_size/2-(search_size+appmenu_size))-prog_size/2)-1, 38);
        }
        
        private void launch_help () {
            try {
                GLib.Process.spawn_async ("/usr/bin/", 
                    {"x-www-browser", 
                    "https://answers.launchpad.net/switchboard"}, 
                    null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
            } catch {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_CRITICAL, 
                        "Unable to open link");
            }
        }
        
        private void launch_translate () {
            try {
                GLib.Process.spawn_async ("/usr/bin/", 
                    {"x-www-browser", 
                    "https://translations.launchpad.net/switchboard"}, 
                    null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
            } catch {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_CRITICAL, 
                        "Unable to open link");
            }
        }
        
        private void launch_report () {
            try {
                GLib.Process.spawn_async ("/usr/bin/", 
                    {"x-www-browser", 
                    "https://bugs.launchpad.net/switchboard"}, 
                    null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
            } catch {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_CRITICAL, 
                        "Unable to open link");
            }
        }
        
        // Create the About Dialog
        private void about_dialog () {
            string[] authors = { "Avi Romanoff <aviromanoff@gmail.com>"};
            Gtk.show_about_dialog (this,
                "program-name", GLib.Environment.get_application_name (),
                "version", SwitchBoard.version,
                "copyright", "Copyright (C) 2011 Avi Romanoff",
                "authors", authors,
                "logo-icon-name", "preferences-desktop",
                null);
        }
    }
    
    private void on_bus_aquired (DBusConnection conn) {
        SettingsApp settings_app = new SettingsApp ();
        try {
            conn.register_object ("/org/elementary/switchboard", settings_app);
        } catch (IOError e) {
        }
    }
    
    public static int main (string[] args) {
        // Startup GTK and pass args by reference
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
