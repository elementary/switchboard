// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2014 Switchboard Developers (http://launchpad.net/switchboard)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public abstract class Switchboard.Plug : GLib.Object {
    public enum Category {
        PERSONAL = 0,
        HARDWARE = 1,
        NETWORK = 2,
        SYSTEM = 3
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
    public Category category { get; construct; }

    /**
     * The unique name representing the plug.
     * 
     * It is also used to recognise it with the open-plug command.
     * for example "system-pantheon-info" for the official Info plug of the pantheon desktop.
     */
    public string code_name { get; construct; }

    /**
     * The localised name of the plug.
     */
    public string display_name { get; construct; }

    /**
     * A short description of the plug.
     */
    public string description { get; construct; }

    /**
     * The icon representing the plug.
     */
    public string icon { get; construct; }

    /**
     * A map of settings:// endpoints and location to pass to the
     * {@link search_callback} method if the value is not %NULL.
     * For example {"input/keyboard", "keyboard"}.
     */
    public Gee.TreeMap<string, string?> supported_settings { get; construct; default = new Gee.TreeMap<string, string?> (null, null); }

    /**
     * Inform if the plug should be shown or not
     */
    public bool can_show { get; set; default=true; }

    /**
     * Inform the application that the plug can now be listed in the available plugs.
     * The application will also listen to the notify::can-show signal.
     *
     * @deprecated: The changing {@link can_show} activate the notify::can-show signal.
     */
    public signal void visibility_changed ();

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
}
