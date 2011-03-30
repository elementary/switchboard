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
using GConf;
using ElementaryWidgets;
 
namespace Wallpaper {

    [DBus (name = "org.elementary.switchboard")]
    public interface SwitchboardController : GLib.Object {

        public abstract void progress_bar_pulse () throws IOError;
        public abstract void progress_bar_show () throws IOError;
        public abstract void progress_bar_hide () throws IOError;
        public abstract void progress_bar_set_fraction () throws IOError;
    }

    public class WallpaperGConf {
     
        string background_key = "/desktop/gnome/background/picture_filename";
        GConf.Client gc = GConf.Client.get_default();
        
        public void update_wallpaper(string file_location) throws GLib.Error {
            stdout.printf(file_location+"\n");
            gc.set_string(background_key, file_location);
        }
    }

    [DBus (name = "org.elementary.switchplug")]
    public class WallpaperSettings : SettingsPlug {

        private SwitchboardController switchboard_controller;
        WallpaperGConf conf_client = new WallpaperGConf();
        ListStore store = new ListStore(2, typeof (Gdk.Pixbuf), typeof (string));
        string WALLPAPER_DIR = "/usr/share/backgrounds";
        TreeIter selected_plug;

        public WallpaperSettings() {
            base("Wallpaper");
            this.switchboard_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.switchboard",
                                                                                 "/org/elementary/switchboard");
            setup_ui();
            this.switchboard_controller.progress_bar_show();
            gather_wallpapers_async();
        }    
        
        private void setup_ui() {
            var vbox = new VBox(false, 0);
            var sw = new ScrolledWindow(null, null);
            sw.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            var view = new IconView.with_model(this.store);
            view.selection_changed.connect(() => selection_changed_cb(view));
            view.set_pixbuf_column (0);
            sw.add_with_viewport(view);
            sw.border_width = 0;
            vbox.pack_end(sw, true, true, 0);
            this.add(vbox);
            this.show_all();
        }
        
        private void selection_changed_cb(IconView view) {
            var selected = view.get_selected_items ();
            if(selected.length() == 1) {
                GLib.Value filename;
                var item = selected.nth_data(0);
                this.store.get_iter(out this.selected_plug, item);
                this.store.get_value (this.selected_plug, 1, out filename);
                this.conf_client.update_wallpaper(WALLPAPER_DIR+"/"+filename.get_string());
            }
        }
        
        private async void gather_wallpapers_async () {
            var directory = File.new_for_path (WALLPAPER_DIR);
            var e = yield directory.enumerate_children_async (FILE_ATTRIBUTE_STANDARD_NAME,
                                                        0, Priority.DEFAULT);
            while (true) {
                var files = yield e.next_files_async (10, Priority.DEFAULT);
                if (files == null) {
                    break;
                }
                foreach (var info in files) {
		            string? filename = (string) info.get_name ();
                    TreeIter root;
                    this.store.append(out root);
                    stdout.printf("Now trying to import: %s\n", filename);
                    try {
                        var image = new Gdk.Pixbuf.from_file_at_size(WALLPAPER_DIR+"/"+filename, 100, 100);
                        var color = Wallpaper.Utilities.average_color(image);
                        Wallpaper.Utilities.match_color_lab(color);
//                        stdout.printf("Red: %f\n", color.R);
//                        stdout.printf("Green: %f\n", color.G);
//                        stdout.printf("Blue: %f\n", color.B);
                        this.store.set(root, 0, image, -1);
                        this.store.set(root, 1, filename, -1);
                    } catch {
//                        stdout.printf("...Awww snap, couldn't load %s!\n", filename);
                    }
                    this.switchboard_controller.progress_bar_pulse();
                    while(events_pending ()) {
                        main_iteration();
                    }
                }
            }
            this.switchboard_controller.progress_bar_hide();
        }
    }

    private void on_bus_aquired (DBusConnection conn) {
        var plug = new WallpaperSettings ();
        try {
            conn.register_object ("/org/elementary/switchplug", plug);
        } catch (IOError e) {
        }
    }

    public static int main (string[] args) {
        GLib.Log.set_default_handler(Log.log_handler);
        Gtk.init (ref args);
        
        Bus.own_name (BusType.SESSION, "org.elementary.switchplug", /* name to register */
                  BusNameOwnerFlags.NONE, /* flags */
                  on_bus_aquired, /* callback function on registration succeded */
                  () => {}, /* callback on name register succeded */
                  () => stderr.printf ("Could not aquire name\n"));
                                                     /* callback on name lost */
        // Run the main loop
        Gtk.main ();
        return 0;
    }
}
