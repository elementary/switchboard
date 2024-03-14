/*
 * Copyright 2017-2022 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

/**
 * SettingsSidebar acts as a controller for a Gtk.Stack; it shows a row of buttons
 * to switch between the various pages of the associated stack widget.
 *
 * All the content for the rows comes from the child properties of a Granite.SettingsPage
 * inside of the Gtk.Stack
 */
public class Switchboard.SettingsSidebar : Gtk.Widget {
    private Gtk.ListBox listbox;

    /**
     * The Gtk.Stack to control
     */
    public Gtk.Stack stack { get; construct; }

    /**
     * Whether to show back and title buttons in the header area
     */
    public bool show_title_buttons { get; set;}

    /**
     * The name of the currently visible Granite.SettingsPage
     */
    public string? visible_child_name {
        get {
            var selected_row = listbox.get_selected_row ();

            if (selected_row == null) {
                return null;
            } else {
                return ((SettingsSidebarRow) selected_row).page.title;
            }
        }
        set {
            weak Gtk.Widget listbox_child = listbox.get_first_child ();
            while (listbox_child != null) {
                if (!(listbox_child is SettingsSidebarRow)) {
                    listbox_child = listbox_child.get_next_sibling ();
                    continue;
                }

                if (((SettingsSidebarRow) listbox_child).page.title == value) {
                    listbox.select_row ((Gtk.ListBoxRow) listbox_child);
                    break;
                }

                listbox_child = listbox_child.get_next_sibling ();
            }
        }
    }

    /**
     * Create a new SettingsSidebar
     */
    public SettingsSidebar (Gtk.Stack stack) {
        Object (stack: stack);
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    class construct {
        set_css_name ("settingssidebar");
    }

    construct {
        listbox = new Gtk.ListBox () {
            hexpand = true,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        listbox.bind_model (stack.pages, create_widget_func);

        var scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = listbox
        };

        var headerbar = new Adw.HeaderBar () {
            show_end_title_buttons = false,
            show_title = false
        };

        var toolbarview = new Adw.ToolbarView () {
            content = scrolled,
            top_bar_style = FLAT
        };
        toolbarview.add_top_bar (headerbar);
        toolbarview.set_parent (this);

        listbox.row_selected.connect ((row) => {
            stack.visible_child = ((SettingsSidebarRow) row).page;
        });

        listbox.set_header_func ((row, before) => {
            var header = ((SettingsSidebarRow) row).header;
            if (header != null) {
                var label = new Gtk.Label (header) {
                    halign = Gtk.Align.START,
                    xalign = 0
                };

                label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
                row.set_header (label);
            }
        });

        stack.notify["visible-child-name"].connect (() => {
            visible_child_name = stack.visible_child_name;
        });

        bind_property ("show-title-buttons", toolbarview, "reveal-top-bars", SYNC_CREATE);
    }

    ~SettingsSidebar () {
        get_first_child ().unparent ();
    }

    private Gtk.Widget create_widget_func (Object object) {
        unowned var stack_page = (Gtk.StackPage) object;
        unowned var page = (SettingsPage) stack_page.child;
        var row = new SettingsSidebarRow (page);

        return row;
    }
}
