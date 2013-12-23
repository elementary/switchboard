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

public class Switchboard.PlugsManager : GLib.Object {
    
    private static Switchboard.PlugsManager? plugs_manager = null;
    
    public static PlugsManager get_default () {
        if (plugs_manager == null)
            plugs_manager = new PlugsManager ();
        return plugs_manager;
    }
    
    [CCode (has_target = false)]
    private delegate Switchboard.Plug RegisterPluginFunction (Module module);
    
    private Gee.LinkedList<Switchboard.Plug> plugs;
    
    public signal void plug_added (Switchboard.Plug plug);
    
    private PlugsManager () {
        plugs = new Gee.LinkedList<Switchboard.Plug> ();
        var base_folder = File.new_for_path (Build.PLUGS_DIR);
        find_plugins (base_folder);
    }

    private void load (string path) {
        if (Module.supported () == false) {
            error ("Switchboard is not supported by this system!");
        }

        Module module = Module.open (path, ModuleFlags.BIND_LAZY);
        if (module == null) {
            critical (Module.error ());
            return;
        }

        void* function;
        module.symbol ("get_plug", out function);
        if (function == null) {
            critical ("get_plug () not found in %s", path);
            return;
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Switchboard.Plug plug = register_plugin (module);
        if (plug == null) {
            critical ("Unknown plugin type for %s !", path);
            return;
        }
        module.make_resident ();
        register_plug (plug);
    }
    
    private void find_plugins (File base_folder) {
        FileInfo file_info = null;
        try {
            var enumerator = base_folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = base_folder.get_child (file_info.get_name ());

                if (file_info.get_file_type () == FileType.REGULAR && GLib.ContentType.equals (file_info.get_content_type (), "application/x-sharedlib")) {
                    load (file.get_path ());
                } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                    find_plugins (file);
                }
            }
        } catch (Error err) {
            warning("Unable to scan plugs folder: %s\n", err.message);
        }
    }
    
    private void register_plug (Switchboard.Plug plug) {
        if (plugs.contains (plug))
            return;
        plugs.add (plug);
        plug_added (plug);
    }
    
    public bool has_plugs () {
        return !plugs.is_empty;
    }
    
    public Gee.Collection<Switchboard.Plug> get_plugs () {
        return plugs.read_only_view;
    }
}