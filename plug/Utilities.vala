/***
BEGIN LICENSE
Copyright (C) 2010 Maxwell Barvian
Copyright (C) 2011 Avi Romanoff
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

using GLib;
using Gtk;
using Cairo;

namespace Wallpaper {

    class Utilities : GLib.Object {
	
        public static Wallpaper.Color average_color (Gdk.Pixbuf source) {
			    double rTotal = 0;
			    double gTotal = 0;
			    double bTotal = 0;
			
			    uchar* dataPtr = source.get_pixels ();
			    double pixels = source.height * source.rowstride / source.n_channels;
			
			    for (int i = 0; i < pixels; i++) {
				    uchar r = dataPtr [0];
				    uchar g = dataPtr [1];
				    uchar b = dataPtr [2];
				
				    uchar max = (uchar) Math.fmax (r, Math.fmax (g, b));
				    uchar min = (uchar) Math.fmin (r, Math.fmin (g, b));
				    double delta = max - min;
				
				    double sat = delta == 0 ? 0 : delta / max;
				    double score = 0.2 + 0.8 * sat;
				
				    rTotal += r * score;
				    gTotal += g * score;
				    bTotal += b * score;
				
				    dataPtr += source.n_channels;
			    }
			
			    return Wallpaper.Color (rTotal / uint8.MAX / pixels,
							     gTotal / uint8.MAX / pixels,
							     bTotal / uint8.MAX / pixels,
							     1).set_val (0.8).multiply_sat (1.15);
	    }
	    
	    public static Wallpaper.Color match_color (Wallpaper.Color input_color) {
	    
		    Gee.HashMap<string, Wallpaper.Color?> colors = new Gee.HashMap<string, Wallpaper.Color?>();
		    colors["red"] = Wallpaper.Color(0.9961, 0.1451, 0.7059, 1.0);
            colors["yellow"] = Wallpaper.Color(1.0000, 1.0000, 0.0392, 1.0);
            colors["blue"] = Wallpaper.Color(0.6667, 0.3255, 1.0000, 1.0);
            colors["green"] = Wallpaper.Color(0.1176, 0.6314, 0.1569, 1.0);
            colors["orange"] = Wallpaper.Color(0.9961, 0.6000, 0.0001, 1.0);
            colors["purple"] = Wallpaper.Color(0.5294, 0.0392, 0.6902, 1.0);
	        
            double r_prom = input_color.R;
            double g_prom = input_color.G;
            double b_prom = input_color.B;
            
            double closest_match = 1.0;
            string match_name = "";
    
	        foreach (string name in colors.keys) {
	            
                double r_cur = colors[name].R;
                double g_cur = colors[name].G;
                double b_cur = colors[name].B;
                
                double current_match = Math.sqrt(((r_cur-r_prom)*(r_cur-r_prom) + (g_cur-g_prom)*(g_cur-g_prom) + (b_cur-b_prom)*(b_cur-b_prom)));
                stdout.printf("Trying %s: %f\n", name, current_match);
                if (current_match < closest_match) {
                    closest_match = current_match;
                    match_name = name;
                }
	        }
            stdout.printf("The euclidian distance to the current color is closest to %f (%s).\n", closest_match, match_name);
            return colors[match_name];
	    }
	}	
}
