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
 
namespace Wallpaper {

public class FileOperator : GLib.Object {

	private static bool is_valid_file_type(string type) {
		return (type.down().has_suffix(".png") || type.down().has_suffix(".jpeg") || type.down().has_suffix(".jpg") || type.down().has_suffix(".gif"));
	}

	public static int count_wallpapers(GLib.File music_folder) {
		GLib.FileInfo file_info = null;
        int index = 0;		

		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
//				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					index++;
				}
                // We need to deal with the lame GNOME xml bullshit.
                // That, or we can actually load in directories into the UI
/*				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					count_music_files(GLib.File.new_for_path(file_path));
                }
*/
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not pre-scan wallpaper folder. Progress percentage may be off: %s\n", err.message);
		}
        return index;
	}

}

[DBus (name = "org.elementary.wallpaper")]
public interface WallpaperController : GLib.Object {

    public abstract void update_wallpaper (string location, int32 show_mode) throws IOError;

}

    public class WallpaperPlug : SwitchPlug {

        KeyFile kf = new KeyFile();
        ListStore store = new ListStore(2, typeof (Gdk.Pixbuf), typeof (string));
        string WALLPAPER_DIR = "/usr/share/backgrounds";
        WallpaperController wallpaper_controller;
        TreeIter selected_plug;

        public WallpaperPlug() {
            base("Wallpapers");
            setup_ui();
            this.wallpaper_controller = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.wallpaper",
                                                                 "/org/elementary/wallpaper");
            gather_wallpapers_async();
        }    
        
        private void setup_ui() {
            var vp = new Viewport(null, null);
            var vbox = new VBox(false, 0);
            vp.set_shadow_type(ShadowType.NONE);
            var sw = new ScrolledWindow(null, null);
            sw.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            var view = new IconView.with_model(this.store);
            view.selection_changed.connect(() => selection_changed_cb(view));
            view.set_pixbuf_column (0);
//            view.set_text_column (1);
            vp.add(view);
            sw.add(vp);
            sw.border_width = 0;
            sw.set_shadow_type(ShadowType.NONE);
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
                this.store.get_value(this.selected_plug, 1, out filename);
                this.wallpaper_controller.update_wallpaper(WALLPAPER_DIR+"/"+filename.get_string(), 1);    
            }
        }

        private async void gather_wallpapers_async () {
            
            this.switchboard_controller.progress_bar_set_visible(true);
            this.switchboard_controller.progress_bar_set_text("Importing wallpapers from "+WALLPAPER_DIR);
            var directory = File.new_for_path (WALLPAPER_DIR);
            double done = 0.0;
            int count = FileOperator.count_wallpapers(directory);
            var e = yield directory.enumerate_children_async (FILE_ATTRIBUTE_STANDARD_NAME,
                                                        0, Priority.DEFAULT);
            
            while (true) {
                var files = yield e.next_files_async (10, Priority.DEFAULT);
                if (files == null) {
                    break;
                }
                foreach (var info in files) {
                    done++;
		            string? filename = (string) info.get_name ();
                    TreeIter root;
                    this.store.append(out root);
                    try {
                        var image = new Gdk.Pixbuf.from_file_at_size(WALLPAPER_DIR+"/"+filename, 100, 100);
//                        var color = Wallpaper.Utilities.average_color(image);
//                        string color_name = Wallpaper.Utilities.match_color_hsv(color);
                        this.store.set(root, 0, image, -1);
                        this.store.set(root, 1, filename, -1);
                    } catch {
                    }
                    this.switchboard_controller.progress_bar_set_fraction(done/count);
                    while(events_pending ()) {
                        main_iteration();
                    }
                }
            }
            this.switchboard_controller.progress_bar_set_visible(false);
        }
    }

    public static void main (string[] args) {
        Gtk.init (ref args);
        new WallpaperPlug ();
        Gtk.main ();
    }
}
