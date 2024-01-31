/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2011-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Avi Romanoff <aviromanoff@gmail.com>
 */

public class Switchboard.CategoryView : Gtk.Box {
    public PlugsSearch plug_search { get; construct; }
    public Gee.ArrayList<SearchEntry?> plug_search_result { get; construct; }

    public string? plug_to_open { get; construct set; default = null; }

    private Gtk.SearchEntry search_box;
    private Gtk.Stack stack;
    private Switchboard.Category personal_category;
    private Switchboard.Category hardware_category;
    private Switchboard.Category network_category;
    private Switchboard.Category system_category;

    class construct {
        set_css_name ("category-view");
    }

    construct {
        var search_box_eventcontrollerkey = new Gtk.EventControllerKey ();

        search_box = new Gtk.SearchEntry () {
            placeholder_text = _("Search Settings")
        };
        search_box.add_controller (search_box_eventcontrollerkey);

        var search_clamp = new Adw.Clamp () {
            child = search_box,
            maximum_size = 800,
            tightening_threshold = 800
        };

        var searchview = new SearchView (search_box);

        var alert_view = new Granite.Placeholder (_("No Settings Found")) {
            description = _("Install settings plugins and re-launch System Settings."),
            icon = new ThemedIcon ("dialog-warning")
        };

        personal_category = new Switchboard.Category (Switchboard.Plug.Category.PERSONAL);
        hardware_category = new Switchboard.Category (Switchboard.Plug.Category.HARDWARE);
        network_category = new Switchboard.Category (Switchboard.Plug.Category.NETWORK);
        system_category = new Switchboard.Category (Switchboard.Plug.Category.SYSTEM);

        plug_search = new PlugsSearch ();
        plug_search_result = new Gee.ArrayList<SearchEntry?> ();

        var category_box = new Gtk.Box (VERTICAL, 0) {
            vexpand = true
        };
        category_box.append (personal_category);
        category_box.append (hardware_category);
        category_box.append (network_category);
        category_box.append (system_category);
        category_box.add_css_class ("category-box");

        stack = new Gtk.Stack () {
            transition_type = CROSSFADE,
            vhomogeneous = false
        };
        stack.add_named (category_box, "category-grid");
        stack.add_child (searchview);

        var clamp = new Adw.Clamp () {
            child = stack,
            maximum_size = 800,
            tightening_threshold = 800
        };

        var scrolled = new Gtk.ScrolledWindow () {
            child = clamp,
            hscrollbar_policy = NEVER
        };

        orientation = VERTICAL;
        append (search_clamp);
        append (scrolled);

        if (Switchboard.PlugsManager.get_default ().has_plugs () == false) {
            stack.add_child (alert_view);
            stack.visible_child = alert_view;
            search_box.sensitive = false;
        }

        search_box.search_changed.connect (() => {
            if (search_box.text.length > 0) {
                stack.visible_child = searchview;
            } else {
                stack.visible_child = category_box;
            }
        });

        search_box.activate.connect (() => {
            searchview.activate_first_item ();
        });

        search_box_eventcontrollerkey.key_released.connect ((keyval, keycode, state) => {
            switch (keyval) {
                case Gdk.Key.Down:
                    search_box.move_focus (TAB_FORWARD);
                    break;
                case Gdk.Key.Escape:
                    search_box.text = "";
                    break;
                default:
                    break;
            }
        });

        var eventcontrollerkey = new Gtk.EventControllerKey ();
        eventcontrollerkey.key_pressed.connect (() => {
            eventcontrollerkey.forward (search_box.get_delegate ());
            return Gdk.EVENT_PROPAGATE;
        });

        add_controller (eventcontrollerkey);
    }

    public CategoryView (string? plug = null) {
        Object (plug_to_open: plug);
    }

    public async void load_default_plugs () {
        var plugsmanager = Switchboard.PlugsManager.get_default ();
        plugsmanager.plug_added.connect ((plug) => {
            add_plug (plug);
        });

        foreach (var plug in plugsmanager.get_plugs ()) {
            add_plug (plug);
        }
    }

    public void add_plug (Switchboard.Plug plug) {
        var icon = new Switchboard.CategoryIcon (plug);

        switch (plug.category) {
            case Switchboard.Plug.Category.PERSONAL:
                personal_category.add (icon);
                break;
            case Switchboard.Plug.Category.HARDWARE:
                hardware_category.add (icon);
                break;
            case Switchboard.Plug.Category.NETWORK:
                network_category.add (icon);
                break;
            case Switchboard.Plug.Category.SYSTEM:
                system_category.add (icon);
                break;
            default:
                return;
        }

        var any_found = false;

        if (personal_category.has_child ()) {
            any_found = true;
        }

        if (hardware_category.has_child ()) {
            any_found = true;
        }

        if (network_category.has_child ()) {
            any_found = true;
        }

        if (system_category.has_child ()) {
            any_found = true;
        }

        if (any_found) {
            stack.visible_child_name = "category-grid";
        }

        if (plug_to_open != null && plug_to_open.has_suffix (plug.code_name)) {
            unowned var app = (SwitchboardApp) GLib.Application.get_default ();
            app.load_plug (plug);
            plug_to_open = null;
        }
    }

    public static string? get_category_name (Switchboard.Plug.Category category) {
        switch (category) {
            case Plug.Category.PERSONAL:
                return _("Personal");
            case Plug.Category.HARDWARE:
                return _("Hardware");
            case Plug.Category.NETWORK:
                return _("Network & Wireless");
            case Plug.Category.SYSTEM:
                return _("Administration");
        }

        return null;
    }
}
