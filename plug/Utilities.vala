/*
# Sassy Backup
#
# Copyright (c) 2010 by Sassy Developers
#    
# License:
# This file is part of sassy.
#
# Sassy is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Sassy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Sassy.  If not, see <http://www.gnu.org/licenses/>.
*/
using GLib;
using Gtk;
using Cairo;

namespace Slingshot.Frontend {

    class Utilities : GLib.Object {
		
	    public static Gtk.Alignment wrap_alignment(Gtk.Widget widget, int top, int right, int bottom, int left) {
		    var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		    alignment.top_padding = top;
		    alignment.right_padding = right;
		    alignment.bottom_padding = bottom;
		    alignment.left_padding = left;
		
		    alignment.add(widget);
		    return alignment;
	    }
		
	    public static void draw_rounded_rectangle(Cairo.Context context, double radius, double offset, Gtk.Allocation size) {
		    context.move_to (size.x + radius, size.y + offset);
		    context.arc (size.x + size.width - radius - offset, size.y + radius + offset, radius, Math.PI * 1.5, Math.PI * 2);
		    context.arc (size.x + size.width - radius - offset, size.y + size.height - radius - offset, radius, 0, Math.PI * 0.5);
		    context.arc (size.x + radius + offset, size.y + size.height - radius - offset, radius, Math.PI * 0.5, Math.PI);
		    context.arc (size.x + radius + offset, size.y + radius + offset, radius, Math.PI, Math.PI * 1.5);
		
        }
        
        public static void truncate_text (Cairo.Context context, Gtk.Allocation size, uint padding, string input, out string truncated, out Cairo.TextExtents truncated_extents) {
            Cairo.TextExtents extents;
            truncated = input;
            context.text_extents (input, out extents);
            
            if (extents.width > (size.width - padding)) {
            
                while (extents.width > (size.width - padding)) {
                    truncated = truncated.slice (0, (int)truncated.length - 1);
                    context.text_extents (truncated, out extents);
                }   
                
                truncated = truncated.slice (0, (int)truncated.length - 3); // make room for ...
                truncated += "...";
            
            }
            
            context.text_extents (truncated, out truncated_extents);
            
        }
        
        public static Slingshot.Frontend.Color average_color (Gdk.Pixbuf source) {
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
			
			    return Slingshot.Frontend.Color (rTotal / uint8.MAX / pixels,
							     gTotal / uint8.MAX / pixels,
							     bTotal / uint8.MAX / pixels,
							     1).set_val (0.8).multiply_sat (1.15);
		    }
		
		}
	
}
		
