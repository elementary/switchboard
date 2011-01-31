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
    public const string plug_exec_dir = "./plugs_exec/";
    public const string app_title = "SwitchBoard";
    
    
    [DBus (name = "org.elementary.SettingsApp")]
    public class SettingsApp : Window {
       
        // Fields
        ToolButton back_button;
        ToolButton forward_button;
        public AppMenu app_menu;
        public Gtk.Socket socket;
        ElementaryEntry find_entry;
        VBox vbox;
        IconView pane_view;
        ListStore store;
        Toolbar toolbar;
        Gtk.IconTheme theme = Gtk.IconTheme.get_default();   
         
        public SettingsApp () {
            // The window poperties
            this.socket = new Gtk.Socket ();
            this.height_request = 500;
            this.position = Gtk.WindowPosition.CENTER;
            this.title = SwitchBoard.app_title;
            destroy.connect(()=> Gtk.main_quit());
            
            // Init
            this.vbox = new VBox (false, 0);
            this.toolbar = new Toolbar ();
            // Create a ListStore with space to hold Name, icon and executable name
            this.store = new ListStore (3, typeof (string), typeof (Gdk.Pixbuf), typeof(string));
            this.pane_view = new IconView.with_model (this.store);
            this.pane_view.set_columns(5);
            this.pane_view.set_text_column (0);
            this.pane_view.set_pixbuf_column (1);
            this.pane_view.selection_changed.connect(this.change_pane);
            
            setup_toolbar ();
            this.vbox.pack_start (this.toolbar, false, false);
            this.vbox.pack_start (this.socket, false, false);
            this.vbox.pack_end (this.pane_view, true, true);
            
            this.add (this.vbox);
            this.socket.hide ();
            load_panes ();
            this.show_all ();
        }
        
        public void change_pane() {
            var selected = this.pane_view.get_selected_items ();
            if(selected.length() == 1) {
                var item = selected.nth_data(0);
                GLib.Value executable;
                TreeIter iter;
                this.store.get_iter(out iter, item);
                this.store.get_value (iter, 2, out executable);
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "selected #%s | executable %s", item.to_string(), executable.get_string());
                // Add launching and view switching here
                
                //Clear selection again
                this.pane_view.unselect_path(item);
            } else {
                GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Selection has been cleared!");
            }
        }
        
        public int grab_wid () {
            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, "Dispatching WID");
            return ((int) this.socket.get_id ());
        }
        
        public void identify (string identity_string) {
            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_DEBUG, 
                    "Identifying %s", identity_string);
            this.update_title(identity_string);
        }
        
        private void update_title(string pane_title) {
            this.title += SwitchBoard.app_title + " - " + pane_title;
        }
        
        private void pack_pane (Gee.HashMap<string, string> plug) {
            var icon_pixbuf = this.theme.load_icon (plug["icon"], 48, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            Gtk.TreeIter root;
            this.store.append (out root);
            this.store.set (root, 0, plug["title"], -1);
            this.store.set (root, 1, icon_pixbuf, -1);
            this.store.set (root, 2, plug["exec"], -1);
        }
        
        private void load_panes () {
            Gee.ArrayList<string> keyfiles = find_panes ();
            foreach (string keyfile in keyfiles) {
                KeyFile kf = new KeyFile();
                Gee.HashMap<string, string> pane = new Gee.HashMap<string, string> ();
                try { kf.load_from_file(SwitchBoard.plug_def_dir + keyfile, KeyFileFlags.NONE); } 
                catch {}
                try { pane["exec"] = kf.get_string (keyfile, "exec"); }
                catch {}
                try { pane["icon"] = kf.get_string (keyfile, "icon"); }
                catch {}
                try { pane["title"] = kf.get_string (keyfile, "title"); }
                catch {}
                pack_pane (pane);
            }
        }
        
        private Gee.ArrayList<string> find_panes () {
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
        
        private void setup_toolbar () {
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
            
            this.back_button = new ToolButton.from_stock(Stock.GO_BACK);
            this.forward_button = new ToolButton.from_stock(Stock.GO_FORWARD);
            
            this.toolbar.add (back_button);
            this.toolbar.add (forward_button);
            this.toolbar.add (spacing);
            this.toolbar.add (toolitem);
            this.toolbar.add (this.app_menu);
        }
        
        private void launch_help () {
            try {
                GLib.Process.spawn_async ("/usr/bin/", 
                    {"x-www-browser", 
                    "https://answers.launchpad.net/elementaryos"}, 
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
                    "https://translations.launchpad.net/elementaryos"}, 
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
                    "https://bugs.launchpad.net/elementaryos"}, 
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
                "copyright", "Copyright (C) 2011 Avi Romanoff", //_("Copyright (C) ThisYear Your Name"), //TODO: set up i18n
                "authors", authors,
                "logo-icon-name", "news-feed",
                //"translator-credits", _("translator-credits"), //TODO: DOES NOT COMPUTE
                null);
        }
    }
    
    void on_bus_aquired (DBusConnection conn) {
        SettingsApp settings_app = new SettingsApp ();
        settings_app.app_menu.grab_focus ();
        try {
            conn.register_object ("/org/elementary/settingsapp", settings_app);
        } catch (IOError e) {
            GLib.log(SwitchBoard.errdomain, LogLevelFlags.LEVEL_CRITICAL, 
                    "Could not register service");
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
        
        Bus.own_name (BusType.SESSION, "org.elementary.SettingsApp", 
                BusNameOwnerFlags.NONE,
                on_bus_aquired,
                () => {},
                () => stderr.printf ("Could not aquire name\n"));
        
        Gtk.main ();
        return 0;
    }
}
