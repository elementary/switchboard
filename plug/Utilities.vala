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
	    
	    public static void rgb_to_hsv (double r, double g, double b, out double h, out double s, out double v)
        {
	        double min = Math.fmin (r, Math.fmin (g, b));
	        double max = Math.fmax (r, Math.fmax (g, b));
	
	        v = max;
	        if (v == 0) {
		        h = 0;
		        s = 0;
		        return;
	        }
	
	        // normalize value to 1
	        r /= v;
	        g /= v;
	        b /= v;
	
	        min = Math.fmin (r, Math.fmin (g, b));
	        max = Math.fmax (r, Math.fmax (g, b));
	
	        double delta = max - min;
	        s = delta;
	        if (s == 0) {
		        h = 0;
		        return;
	        }
	
	        // normalize saturation to 1
	        r = (r - min) / delta;
	        g = (g - min) / delta;
	        b = (b - min) / delta;
	
	        if (max == r) {
		        h = 0 + 60 * (g - b);
		        if (h < 0)
			        h += 360;
	        } else if (max == g) {
		        h = 120 + 60 * (b - r);
	        } else {
		        h = 240 + 60 * (r - g);
	        }
        }

        public static string match_color_rgb (Wallpaper.Color input_color) {

            Gee.HashMap<string, Wallpaper.Color?> colors = new Gee.HashMap<string, Wallpaper.Color?>();
            
            // Primary
            colors["red"] = Wallpaper.Color(1.0000, 0.0000, 0.0000, 1.0);
            colors["green"] = Wallpaper.Color(0.0000, 1.0000, 0.0000, 1.0);
            colors["blue"] = Wallpaper.Color(0.0000, 0.0000, 1.0000, 1.0);

            // Secondary
            colors["yellow"] = Wallpaper.Color(1.0000, 1.0000, 0.0000, 1.0);
            colors["cyan"] = Wallpaper.Color(0.0000, 1.0000, 1.0000, 1.0);
            colors["magenta"] = Wallpaper.Color(1.0000, 0.0000, 1.0000, 1.0);
            
            // Tertiary
            colors["orange"] = Wallpaper.Color(1.0000, 0.4980, 0.0000, 1.0);
            colors["chartreuse green"] = Wallpaper.Color(0.4980, 1.0000, 0.0000, 1.0);
            colors["spring green"] = Wallpaper.Color(0.0000, 1.0000, 0.4980, 1.0);
            colors["azure"] = Wallpaper.Color(0.0000, 0.4980, 1.0000, 1.0);
            colors["violet"] = Wallpaper.Color(0.4980, 0.0000, 1.0000, 1.0);
            colors["rose"] = Wallpaper.Color(1.0000, 0.0000, 0.4980, 1.0);

            double r_prom = input_color.R;
            double g_prom = input_color.G;
            double b_prom = input_color.B;
            
            double h, s, v;
            rgb_to_hsv (r_prom, g_prom, b_prom, out h, out s, out v);
            stdout.printf("\nH: %f\nS: %f\nV:%f\n\n", h, s, v);
            stdout.printf("R: %f\nG: %f\nB:%f\n\n", r_prom, g_prom, b_prom);
            
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
            return match_name;
        }

        public static string match_color_hsv (Wallpaper.Color input_color) {

            Gee.HashMap<string, Wallpaper.Color?> colors = new Gee.HashMap<string, Wallpaper.Color?>();
            
            // Primary
            colors["red"] = Wallpaper.Color(1.0000, 0.0000, 0.0000, 1.0);
            colors["green"] = Wallpaper.Color(0.0000, 1.0000, 0.0000, 1.0);
            colors["blue"] = Wallpaper.Color(0.0000, 0.0000, 1.0000, 1.0);

//            // Secondary
            colors["yellow"] = Wallpaper.Color(1.0000, 1.0000, 0.0000, 1.0);
            colors["cyan"] = Wallpaper.Color(0.0000, 1.0000, 1.0000, 1.0);
            colors["magenta"] = Wallpaper.Color(1.0000, 0.0000, 1.0000, 1.0);
//            
//            // Tertiary
            colors["orange"] = Wallpaper.Color(1.0000, 0.4980, 0.0000, 1.0);
            colors["chartreuse green"] = Wallpaper.Color(0.4980, 1.0000, 0.0000, 1.0);
            colors["spring green"] = Wallpaper.Color(0.0000, 1.0000, 0.4980, 1.0);
            colors["azure"] = Wallpaper.Color(0.0000, 0.4980, 1.0000, 1.0);
            colors["violet"] = Wallpaper.Color(0.4980, 0.0000, 1.0000, 1.0);
            colors["rose"] = Wallpaper.Color(1.0000, 0.0000, 0.4980, 1.0);

			double h_prom, s_prom, v_prom;
            double r_prom = input_color.R;
            double g_prom = input_color.G;
            double b_prom = input_color.B;
            rgb_to_hsv (r_prom, g_prom, b_prom, out h_prom, out s_prom, out v_prom);
            
            
            if (v_prom < 0.1) {
                return "black";
            }
            
            if (s_prom < 0.1) {
                if (v_prom < 0.9) {
                    return "grey";
                }
            }
            
            double closest_match = 360.0;
            string match_name = "";
    
           foreach (string name in colors.keys) {
             
    			double h_cur, s_cur, v_cur;
                rgb_to_hsv (colors[name].R, colors[name].G, colors[name].B, out h_cur, out s_cur, out v_cur);
                
                double current_match = Math.sqrt(((h_cur-h_prom)*(h_cur-h_prom)));
                stdout.printf("Trying %s: %f\n", name, current_match);
                if (current_match < closest_match) {
                    closest_match = current_match;
                    match_name = name;
                }
           }
            stdout.printf("The euclidian distance to the current color is closest to %f (%s).\n", closest_match, match_name);
            return match_name;
       }
    }
}
