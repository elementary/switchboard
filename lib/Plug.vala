// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Switchboard Developers (http://launchpad.net/switchboard)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public abstract class Switchboard.Plug : GLib.Object {
    
    private string sep = "<sep>"; //For search propurses
    public Category category;
    public string code_name; // The name it is recognised with the open-plug command
    public string display_name; // The localised plug name
    public string description; // A short description
    public string icon;
    
    public enum Category {
        PERSONAL = 0,
        HARDWARE = 1,
        NETWORK = 2,
        SYSTEM = 3,
        OTHER = 4
    }
    
    public abstract Gtk.Widget get_widget ();
    public abstract void close ();
    
    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public abstract async Gee.TreeMap<string, string> search (string search);
} 
