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
    
    public enum Category {
        PERSONAL = 0,
        HARDWARE = 1,
        NETWORK = 2,
        SYSTEM = 3,
        OTHER = 4
    }
    
    /**
     * The common used separator.
     */
    public const string SEP = "<sep>";
    
    /**
     * The category under which the plug will be stored.
     * 
     * Possible {@link Category} values are PERSONAL, HARDWARE, NETWORK or SYSTEM.
     */
    public Category category { get; set; }
    
    /**
     * The unique name representing the plug.
     * 
     * It is also used to recognise it with the open-plug command.
     * for example "system-pantheon-info" for the official Info plug of the pantheon desktop.
     */
    public string code_name { get; set; }
    
    /**
     * The localised name of the plug.
     */
    public string display_name { get; set; }
    
    /**
     * A short description of the plug.
     */
    public string description { get; set; }
    
    /**
     * The icon representing the plug.
     */
    public string icon { get; set; }
    
    /**
     * Returns the widget that contain the whole interface.
     *
     * @return a {@link Gtk.Widget} containing the interface.
     */
    public abstract Gtk.Widget get_widget ();
    
    /**
     * Called when the plug appears to the user.
     */
    public abstract void shown ();
    
    /**
     * Called when the plug disappear to the user.
     * 
     * This is not called when the plug got destroyed or the window is closed, use ~Plug () instead.
     */
    public abstract void hidden ();
    
    /**
     * This function should return the widget that contain the whole interface.
     * 
     * When the user click on an action, the second parameter is send to the {@link search_callback} method
     * 
     * @param search a {@link string} that represent the search.
     * @return a {@link Gee.TreeMap} containing two strings like {"Keyboard → Behavior → Duration", "keyboard<sep>behavior"}.
     */
    public abstract async Gee.TreeMap<string, string> search (string search);
    
    /**
     * This function is used when the user click on a search result, it should show the selected setting (right tab…).
     * 
     * @param location a {@link string} that represents the setting to show.
     */
    public abstract void search_callback (string location);
    
    /**
     * Called when the plug is loaded (basically at Switchboard startup)
     */
    public abstract void activate ();
    
    /**
     * Called when the plug is removed
     */
    public abstract void deactivate ();
}
