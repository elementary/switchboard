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
     * A header to be sorted under in a Granite.SettingsSidebar
     */
    public string? header { get; construct; }

    /**
     * A status string to be displayed underneath the title in a Granite.SettingsSidebar
     */
    public string status { get; construct set; }

    /**
     * An icon to be displayed in the header and sidebar
     */
    public Icon icon { get; construct set; default = new ThemedIcon ("preferences-other"); }

    /**
     * A title to be displayed in a Granite.SettingsSidebar
     */
    public string title { get; construct set; }

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
    public bool activatable { get; construct; default = false; }

    /**
     * Creates a {@link Adw.Avatar} to use instead of #icon
     */
    public bool with_avatar { get; construct; default = false; }

    /**
     * Custom image to use with avatar
     */
    public Gdk.Paintable avatar_paintable { get; set; }

    /**
     * Creates a {@link Gtk.Label} with a page description in the header of #this
     */
    public string description { get; construct set; }

    /**
     * Whether to show title buttons at the end of the header area
     */
    public bool show_end_title_buttons { get; set;}

    private Adw.Clamp content_area;
    private Gtk.ActionBar action_bar;
    private Gtk.SizeGroup start_button_group;
    private Gtk.SizeGroup end_button_group;

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    class construct {
        set_css_name ("settingspage");
    }

    construct {
        Gtk.Widget header_widget;

        if (!with_avatar) {
            header_widget = new Gtk.Image.from_gicon (icon) {
                icon_size = Gtk.IconSize.LARGE,
                valign = Gtk.Align.START
            };

            bind_property ("icon", header_widget, "gicon");
        } else {
            header_widget = new Adw.Avatar (48, title, true) {
                valign = START
            };

            bind_property ("avatar-paintable", header_widget, "custom-image", SYNC_CREATE);
            bind_property ("title", header_widget, "text");
        }

        var title_label = new Gtk.Label (title) {
            hexpand = true,
            wrap = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label (description) {
            selectable = true,
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var header_area = new Gtk.Grid () {
            halign = CENTER
        };
        header_area.attach (title_label, 1, 0);
        header_area.add_css_class ("header-area");

        if (description != null) {
            header_area.attach (header_widget, 0, 0, 1, 2);
            header_area.attach (description_label, 1, 1, 2);
        } else {
            header_area.attach (header_widget, 0, 0);
        }

        if (activatable) {
            status_switch = new Gtk.Switch () {
                valign = Gtk.Align.START
            };
            header_area.attach (status_switch, 2, 0);
        }

        var end_widget = new Gtk.WindowControls (END) {
            valign = START
        };

        var headerbar = new Gtk.CenterBox () {
            center_widget = header_area,
            end_widget = end_widget
        };

        var window_handle = new Gtk.WindowHandle () {
            child = headerbar
        };

        content_area = new Adw.Clamp () {
            maximum_size = 600,
            tightening_threshold = 600,
            vexpand = true
        };
        content_area.add_css_class ("content-area");

        var size_group = new Gtk.SizeGroup (HORIZONTAL);
        size_group.add_widget (header_area);
        size_group.add_widget (content_area);

        var scrolled = new Gtk.ScrolledWindow () {
            child = content_area,
            hscrollbar_policy = NEVER
        };

        start_button_group = new Gtk.SizeGroup (HORIZONTAL);
        end_button_group = new Gtk.SizeGroup (HORIZONTAL);

        action_bar = new Gtk.ActionBar () {
            revealed = false
        };
        action_bar.add_css_class ("action-area");

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.append (window_handle);
        grid.append (scrolled);
        grid.append (action_bar);
        grid.set_parent (this);

        bind_property ("description", description_label, "label");
        bind_property ("title", title_label, "label");
        bind_property ("show-end-title-buttons", end_widget, "visible", SYNC_CREATE);

        notify["description"].connect (() => {
            if (description_label.parent == null) {
                header_area.remove (header_widget);
                header_area.attach (header_widget, 0, 0, 1, 2);
                header_area.attach (description_label, 1, 1, 2);
            }
        });
    }

    ~SettingsPage () {
        get_first_child ().unparent ();
    }

    public Gtk.Button add_start_button (string label) {
        var button = new Gtk.Button.with_label (label);

        action_bar.pack_start (button);
        action_bar.revealed = true;

        start_button_group.add_widget (button);

        return button;
    }

    public Gtk.Button add_button (string label) {
        var button = new Gtk.Button.with_label (label);

        action_bar.pack_end (button);
        action_bar.revealed = true;

        end_button_group.add_widget (button);

        return button;
    }
}
