/*
 * Copyright 2017–2022 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

/**
 * SimpleSettingsPage is a widget divided into three sections: a predefined header,
 * a content area, and an action area.
 */

public abstract class Switchboard.SimpleSettingsPage : Switchboard.SettingsPage {
    private Gtk.Label description_label;
    private string _description;
    private Adw.Clamp content_area;

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
    public string description {
        get {
            return _description;
        }
        construct set {
            if (description_label != null) {
                description_label.label = value;
            }
            _description = value;
        }
    }

    /**
     * Creates a new SimpleSettingsPage
     * Deprecated: Subclass this instead.
     */
    protected SimpleSettingsPage () {

    }

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
            selectable = true,
            wrap = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var header_area = new Gtk.Grid ();
        header_area.add_css_class ("header-area");
        header_area.attach (title_label, 1, 0);

        if (description != null) {
            description_label = new Gtk.Label (description) {
                selectable = true,
                use_markup = true,
                wrap = true,
                xalign = 0
            };

            header_area.attach (header_icon, 0, 0, 1, 2);
            header_area.attach (description_label, 1, 1, 2);
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

        content_area = new Adw.Clamp () {
            vexpand = true
        };
        content_area.add_css_class ("content-area");

        action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.END
        };
        action_area.add_css_class ("buttonbox");

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.append (header_clamp);
        grid.append (content_area);
        grid.append (action_area);

        var scrolled = new Gtk.ScrolledWindow () {
            child = grid,
            hscrollbar_policy = NEVER
        };
        scrolled.set_parent (this);

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

    ~SimpleSettingsPage () {
        get_first_child ().unparent ();
    }
}
