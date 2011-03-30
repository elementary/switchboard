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
	    
	    public static Wallpaper.Color match_color_rgb (Wallpaper.Color input_color) {
	    
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
	    
	    public static Wallpaper.Color match_color_lab (Wallpaper.Color input_color) {
	        
            double r_prom = input_color.R;
            double g_prom = input_color.G;
            double b_prom = input_color.B;
            
            stdout.printf("R:%f\nG:%f\nB:%f\n\n", r_prom,g_prom, b_prom);
            
            if (r_prom > 0.04045) {
                r_prom = Math.pow(((g_prom + 0.055) / 1.055), 2.4);
            } else {
                r_prom /= 12.92;
            }
            if (g_prom > 0.04045) {
                g_prom = Math.pow(((g_prom + 0.055) / 1.055), 2.4);
            } else {
                g_prom /= 12.92;
            }
            if (b_prom > 0.04045) {
                b_prom = Math.pow(((g_prom + 0.055) / 1.055), 2.4);
            } else {
                b_prom /= 12.92;
            }
            
            r_prom *= 100;
            g_prom *= 100;
            b_prom *= 100;
            
            
            double x_prom = r_prom * 0.4124 + g_prom * 0.3576 + b_prom * 0.1805;
            double y_prom = r_prom * 0.2126 + g_prom * 0.7152 + b_prom * 0.0722;
            double z_prom = r_prom * 0.0193 + g_prom * 0.1192 + b_prom * 0.9505;
            
            stdout.printf("X:%f\nY:%f\nZ:%f\n\n", x_prom, y_prom, z_prom);
            
            double temp_x = x_prom / 95.047;
            double temp_y = y_prom / 100.000;
            double temp_z = z_prom / 108.883;
            
            stdout.printf("X:%f\nY:%f\nZ:%f\n\n", temp_x, temp_y, temp_z);
            
//            stdout.printf("X:%f\n", temp_x);
            if (temp_x > 0.008856) {
                temp_x = Math.pow(temp_x, Math.sqrt(3));
//                stdout.printf("X:%f\n", temp_x);
            } else {
                temp_x = (7.787 * temp_x) + (16/116);
            }
            if (temp_y > 0.008856) {
                temp_y = Math.pow(temp_y, Math.sqrt(3));
            } else {
                temp_y = (7.787 * temp_y) + (16/116);
            }
            if (temp_z > 0.008856) {
                temp_z = Math.pow(temp_z, Math.sqrt(3));
            } else {
                temp_z = (7.787 * temp_z) + (16/116);
            }
            
            stdout.printf("X:%f\nY:%f\nZ:%f\n\n", temp_x, temp_y, temp_z);
            
            double L = ((116 * temp_y) - 16);
            double A = (500 * (temp_x - temp_y));
            double B = (200 * (temp_y - temp_z));
            
            stdout.printf("L:%f\nA:%f\nB:%f\n\n", L, A, B);
                        
        return input_color;
	        
	    }	
    }
}
