/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * LinkRow is a {@link Gtk.ListBoxRow} subclass with a built-in {@link Gtk.UriLauncher}
 * and an accessible role of {@link Gtk.AccessibleRole.LINK}
 */
public class Switchboard.LinkRow : Gtk.ListBoxRow {
    /**
     * The URI bound to #this
     */
    public string uri { get; construct; }

    /**
     * An icon to be displayed at the start of #this
     */
    public Icon icon { get; construct; default = new ThemedIcon ("preferences-other"); }

    /**
     * Text of the label inside the row
     */
    public string label { get; construct; }

    /**
     * A named color corresponding to the list of accent color style classes in the elementary stylesheet.
     * Uses user accent color if left blank
     */
    public string color { get; construct; }

    /**
     * Creates a new Switchboard.LinkRow
     */
    public LinkRow (string uri, string label, Icon icon, string color = "") {
        Object (
            uri: uri,
            label: label,
            icon: icon,
            color: color
        );
    }

    class construct {
        set_accessible_role (LINK);
    }

    construct {
        var image = new Gtk.Image.from_gicon (icon) {
            pixel_size = 16
        };
        image.add_css_class (Granite.STYLE_CLASS_ACCENT);
        image.add_css_class (color);

        var left_label = new Gtk.Label (label) {
            hexpand = true,
            xalign = 0
        };

        var link_image = new Gtk.Image.from_icon_name ("adw-external-link-symbolic");

        var box = new Gtk.Box (HORIZONTAL, 0);
        box.append (image);
        box.append (left_label);
        box.append (link_image);

        child = box;
        add_css_class ("link");
    }

    /**
     * Launches the uri bound to #this
     */
    public override void activate () {
        var uri_launcher = new Gtk.UriLauncher (uri);
        uri_launcher.launch.begin (
            ((Gtk.Application) GLib.Application.get_default ()).active_window,
            null
        );
    }
}
