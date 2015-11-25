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
    public Gee.TreeMap<string, string> all_search_entries { get; private set;}
    
    private PlugsManager () {
        all_search_entries = new Gee.TreeMap<string, string> (null, null);
        plugs = new Gee.LinkedList<Switchboard.Plug> ();
        var base_folder = File.new_for_path (Build.PLUGS_DIR);
        find_plugins (base_folder);
        get_search_entries ("");
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
            warning("Unable to scan plugs folder %s: %s\n", base_folder.get_path (), err.message);
        }
    }
    
    private void register_plug (Switchboard.Plug plug) {
        debug("%s registered", plug.code_name);
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

    public void get_search_entries (string filter) {
        var search_entries = new Gee.TreeMap<string, string> (null, null);
        warning("start search");
        foreach (Switchboard.Plug tmp_plug in plugs) {
            tmp_plug.search.begin (filter, (obj, res) => {
                search_entries = tmp_plug.search.end (res);
                if (search_entries.size < 0) {
                    string[] keys = search_entries.keys.to_array ();
                    string[] values = search_entries.values.to_array ();
                    for (int i =0;i<search_entries.size;i++) {
                        all_search_entries.set(keys[i], values[i]);
                    }
                }
            });
        }
    }
}
