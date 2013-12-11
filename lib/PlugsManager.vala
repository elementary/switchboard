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
    
    [CCode (has_target = false)]
    private delegate Switchboard.Plug RegisterPluginFunction (Module module);
    
    private Gee.LinkedList<unowned Switchboard.Plug> plugs;
    
    public signal void plug_added (Switchboard.Plug plug);
    
    public static PlugsManager get_default () {
        if (plugs_manager == null)
            plugs_manager = new PlugsManager ();
        return plugs_manager;
    }
    
    private PlugsManager () {
        plugs = new Gee.LinkedList<Switchboard.Plug> ();
    }

    private void load (string path) {
        if (Module.supported () == false) {
            warning ("Switchboard is not supported by this system");
            return;
        }

        Module module = Module.open (path, ModuleFlags.BIND_LAZY);
        if (module == null) {
            warning (Module.error ());
            return;
        }

        void* function;
        module.symbol ("get_plug", out function);
        if (function == null) {
            warning ("get_plug () not found in %s", path);
            return;
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Switchboard.Plug plug = register_plugin (module);
        if (plug == null) {
            warning ("Unknown plugin type for %s !", path);
            return;
        }
        module.make_resident ();
        plug.activate ();
    }
    
    private int count_plugins (File base_folder, ref Gee.LinkedList<string> files) {
        FileInfo file_info = null;
        int index = 0;
        try {
            var enumerator = base_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = base_folder.get_child (file_info.get_name ());

                if (file_info.get_file_type () == FileType.REGULAR && GLib.ContentType.equals (file_info.get_content_type (), "application/x-sharedlib")) {
                    index++;
                    files.add (file.get_path ());
                } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                    count_plugins (file, ref files);
                }
            }
        }
        catch(Error err) {
            warning("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
        }

        return index;
    }
    
    public void activate () {
        var base_folder = File.new_for_path (Build.PLUGS_DIR);
        var files = new Gee.LinkedList<string> ();
        count_plugins (base_folder, ref files);
        foreach (var file in files) {
            load (file);
        }
    }
    
    public void register_plug (Switchboard.Plug plug) {
        if (plugs.contains (plug) == false) {
            plugs.add (plug);
            plug_added (plug);
        }
    }
    
    public bool has_plugs () {
        return !plugs.is_empty;
    }
}
