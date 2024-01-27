/*
 * Copyright 2017–2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * SettingsPage is a {@link Gtk.Widget} subclass with properties used
 * by Switchboard.SettingsSidebar
 */
public abstract class Switchboard.SettingsPage : Gtk.Widget {
    /**
     * Used to display a status icon overlayed on the display_widget in a Granite.SettingsSidebar
     */
    public enum StatusType {
        ERROR,
        OFFLINE,
        SUCCESS,
        WARNING,
        NONE
    }

    /**
     * Selects a colored icon to be displayed in a Granite.SettingsSidebar
     */
    public StatusType status_type { get; set; default = StatusType.NONE; }

    /**
     * A widget to display in place of an icon in a Granite.SettingsSidebar
     */
    public Gtk.Widget? display_widget { get; construct; }

    /**
     * A header to be sorted under in a Granite.SettingsSidebar
     */
    public string? header { get; construct; }

    /**
     * A status string to be displayed underneath the title in a Granite.SettingsSidebar
     */
    public string status { get; construct set; }

    /**
     * An icon name to be displayed in a Granite.SettingsSidebar
     */
    public string? icon_name { get; construct set; }

    /**
     * A title to be displayed in a Granite.SettingsSidebar
     */
    public string title { get; construct set; }

    /**
     * A {@link Gtk.Box} used as the action area for #this
     */
    public Gtk.Box action_area { get; construct; }

    /**
     * The child widget for the content area
     */
    public Gtk.Widget child {
        get {
            return content_area.child;
        }
        set {
            content_area.child = value;
        }
    }

    /**
     * A {@link Gtk.Switch} that appears in the header area when #this.activatable is #true. #status_switch will be #null when #this.activatable is #false
     */
    public Gtk.Switch? status_switch { get; construct; }

    /**
     * Creates a {@link Gtk.Switch} #status_switch in the header of #this
     */
    public bool activatable { get; construct; }

    /**
     * Creates a {@link Gtk.Label} with a page description in the header of #this
     */
    public string description { get; construct set; }

    private Adw.Clamp content_area;

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    class construct {
        set_css_name ("simplesettingspage");
    }

    construct {
        var header_icon = new Gtk.Image.from_icon_name (icon_name) {
            icon_size = Gtk.IconSize.LARGE,
            valign = Gtk.Align.START
        };

        var title_label = new Gtk.Label (title) {
            hexpand = true,
            wrap = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var header_area = new Gtk.Grid ();
        header_area.attach (title_label, 1, 0);

        if (description != null) {
            var description_label = new Gtk.Label (description) {
                selectable = true,
                use_markup = true,
                wrap = true,
                xalign = 0
            };

            header_area.attach (header_icon, 0, 0, 1, 2);
            header_area.attach (description_label, 1, 1, 2);

            bind_property ("description", description_label, "label");
        } else {
            header_area.attach (header_icon, 0, 0);
        }

        if (activatable) {
            status_switch = new Gtk.Switch () {
                valign = Gtk.Align.START
            };
            header_area.attach (status_switch, 2, 0);
        }

        var header_clamp = new Adw.Clamp () {
            child = header_area
        };
        header_clamp.add_css_class ("header-area");

        var window_handle = new Gtk.WindowHandle () {
            child = header_clamp
        };

        content_area = new Adw.Clamp () {
            vexpand = true
        };
        content_area.add_css_class ("content-area");

        var scrolled = new Gtk.ScrolledWindow () {
            child = content_area,
            hscrollbar_policy = NEVER
        };

        action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.END
        };
        action_area.add_css_class ("buttonbox");

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.append (window_handle);
        grid.append (scrolled);
        grid.append (action_area);
        grid.set_parent (this);

        notify["icon-name"].connect (() => {
            if (header_icon != null) {
                header_icon.icon_name = icon_name;
            }
        });

        notify["title"].connect (() => {
            if (title_label != null) {
                title_label.label = title;
            }
        });
    }

    ~SettingsPage () {
        get_first_child ().unparent ();
    }
}
