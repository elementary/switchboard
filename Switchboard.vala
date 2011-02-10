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
    public const string version = "0.1 pre-alpha";
    public const string errdomain = "switchboard";
    public const string plug_def_dir = "./plugs/";
    public const string plug_exec_dir = "./plug/";
    public const string app_title = "SwitchBoard";
    
    [DBus (name = "org.elementary.switchboard")]

    public class SettingsApp : Window {
       
        /* Toolbar widgets */
        private Toolbar toolbar;
        private ToolButton navigation_button;
        private ElementaryEntry find_entry;
        public AppMenu app_menu;
        
        /* Content Area widgets */
        private VBox vbox;
        public Gtk.Socket socket;
        private IconView plug_view;
        
        /* Plugging Data */
        private TreeIter selected_plug;
        private bool socket_shown;
        
        
        /* Icon View Data */
        private ListStore store;
        private Gtk.IconTheme theme = Gtk.IconTheme.get_default();
        
        
        public SettingsApp () {
            /* Setup window */
            this.height_request = 500;
            this.position = Gtk.WindowPosition.CENTER;
            this.title = SwitchBoard.app_title;
            this.destroy.connect(()=> Gtk.main_quit());
            
            /* Setup Plug Socket */
            this.socket = new Gtk.Socket ();
            this.socket.plug_added.connect(this.switch_to_socket);
            this.socket.plug_removed.connect(this.switch_to_icons);
            this.socket.hide();
            
            /* Setup icon view */
            // Create a ListStore with space to hold Name, icon and executable name
            this.store = new ListStore (3, typeof (string), typeof (Gdk.Pixbuf), typeof(string));
            this.plug_view = new IconView.with_model (this.store);
            this.plug_view.set_columns(6);
            this.plug_view.set_text_column (0);
            this.plug_view.set_pixbuf_column (1);
            this.plug_view.selection_changed.connect(this.load_plug);
            var color = Gdk.Color ();
            Gdk.Color.parse ("#d9d9d9", out color);
            this.plug_view.modify_base (Gtk.StateType.NORMAL, color);
            
            /* Setup toolbar */
            setup_toolbar ();
            
            /* Wire up interface */
            this.vbox = new VBox (false, 0);
            this.vbox.pack_start (this.toolbar, false, false);
            this.vbox.pack_start (this.socket, false, false);
            this.vbox.pack_end (this.plug_view, true, true);
            
            this.add (this.vbox);
            
            this.enumerate_plugs ();
            this.show_all ();
        }
        
        /****************/
        /* D-Bus methods */
        /****************/
        
        public int get_socket_wid() {
            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Dispatching WID");
            return ((int) this.socket.get_id ());
        }
        
        /*****************/
        /* plug handlers */
        /*****************/
        
        public void load_plug() {
            var selected = this.plug_view.get_selected_items ();
            if(selected.length() == 1) {
                GLib.Value title;
                GLib.Value executable;
                var item = selected.nth_data(0);
                this.store.get_iter(out selected_plug, item);
                this.store.get_value (selected_plug, 0, out title);
                this.store.get_value (selected_plug, 2, out executable);
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Selected plug: name %s | executable %s", title.get_string(), executable.get_string());
                /* Launch plug's executable */
                try {
                    GLib.Process.spawn_command_line_async (plug_exec_dir + executable.get_string());
                    this.load_plug_title (title.get_string());
                    // ensure the button is sensitive; it might be the first plug loaded
                    this.navigation_button.set_sensitive(true);
                    this.navigation_button.stock_id = Gtk.Stock.HOME;
                }
                catch {
                    GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Failed to launch plug: name %s | executable %s", title.get_string(), executable.get_string());
                }
                /* Clear selection again */
                this.plug_view.unselect_path(item);
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
        public void switch_to_socket() {
            this.plug_view.hide();
            this.socket.show();
            this.socket_shown = true;
        }
        
        // Switch back to the icons
        public bool switch_to_icons() {
            this.socket.hide ();
            this.plug_view.show();
            this.reset_title ();
            this.socket_shown = false;
            return true;
        }
        
        private void enumerate_plugs () {
            Gee.ArrayList<string> keyfiles = find_plugs ();
            foreach (string keyfile in keyfiles) {
                KeyFile kf = new KeyFile();
                Gee.HashMap<string, string> plug = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(SwitchBoard.plug_def_dir + keyfile, KeyFileFlags.NONE); } 
                catch {}
                try { plug["exec"] = kf.get_string (keyfile, "exec"); }
                catch {}
                try { plug["icon"] = kf.get_string (keyfile, "icon"); }
                catch {}
                try { plug["title"] = kf.get_string (keyfile, "title"); }
                catch {}
                add_plug (plug);
            }
        }
        
        // Find all .plug files
        private Gee.ArrayList<string> find_plugs () {
            var directory = File.new_for_path (SwitchBoard.plug_def_dir);
            var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);
            Gee.ArrayList<string> keyfiles = new Gee.ArrayList<string> ();
            
            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                string? file_name = (string) file_info.get_name ();
                if (file_name.length < 5) { continue; }
                if (file_name[-5:file_name.length] == ".plug" ) {
                    keyfiles.add(file_name);
                }
            }
            return keyfiles;
        }
        
        // Add plug to the IconView's ListStore
        private void add_plug (Gee.HashMap<string, string> plug) {
            var icon_pixbuf = this.theme.load_icon (plug["icon"], 48, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            Gtk.TreeIter root;
            this.store.append (out root);
            this.store.set (root, 0, plug["title"], -1);
            this.store.set (root, 1, icon_pixbuf, -1);
            this.store.set (root, 2, plug["exec"], -1);
        }
        
        private void setup_toolbar () {
            this.toolbar = new Toolbar ();
            var menu = new Menu ();
            this.app_menu = new AppMenu.from_stock(Gtk.Stock.PROPERTIES, IconSize.MENU, "Menu", menu);
            
            MenuItem go_help = new MenuItem.with_label ("Get Help Online...");
            MenuItem go_translate = new MenuItem.with_label ("Translate This Application...");
            MenuItem go_report = new MenuItem.with_label ("Report a Problem...");
            MenuItem about = new MenuItem.with_label ("About");
            menu.append (go_help);
            menu.append (go_translate);
            menu.append (go_report);
            menu.append (about);
            menu.insert(new SeparatorMenuItem(), 3);
            
            about.activate.connect (about_dialog);
            go_help.activate.connect (launch_help);
            go_translate.activate.connect (launch_translate);
            go_report.activate.connect (launch_report);
            
            var spacing = new ToolItem ();
            spacing.set_expand (true); 
            
            this.find_entry = new ElementarySearchEntry ("Type to search ...");
            var toolitem = new Gtk.ToolItem ();
            toolitem.add (find_entry);
            
            this.navigation_button = new ToolButton.from_stock(Stock.GO_BACK);
            this.navigation_button.clicked.connect(this.handle_navigation_button_clicked);
            
            this.navigation_button.set_sensitive (false);
            
            this.toolbar.add (navigation_button);
            this.toolbar.add (spacing);
            this.toolbar.add (toolitem);
            this.toolbar.add (this.app_menu);
            
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
        settings_app.app_menu.grab_focus ();
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
