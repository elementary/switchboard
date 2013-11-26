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
    
    private Peas.Engine engine;
    private Peas.ExtensionSet exts;
    public Gee.LinkedList<Switchboard.Plug> plugs;
    
    public signal void plug_added (Switchboard.Plug plug);
    
    private PlugsManager () {
        plugs = new Gee.LinkedList<Switchboard.Plug> ();
        
        /* Let's init the engine */
        engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");
        engine.enable_loader ("gjs");
        engine.add_search_path (Build.PLUGS_DIR + "/personal", null);
        engine.add_search_path (Build.PLUGS_DIR + "/hardware", null);
        engine.add_search_path (Build.PLUGS_DIR + "/network", null);
        engine.add_search_path (Build.PLUGS_DIR + "/system", null);
        engine.add_search_path (Build.PLUGS_DIR, null);
    }
    
    public void activate () {
        
        foreach (var plugin in engine.get_plugin_list ()) {
            engine.try_load_plugin (plugin);
        }

        /* Our extension set */
        exts = new Peas.ExtensionSet (engine, typeof (Peas.Activatable), null);

        exts.extension_added.connect ( (info, ext) => {
            ((Peas.Activatable) ext).activate ();
        });
        exts.extension_removed.connect (on_extension_removed);
        
        exts.foreach (on_extension_added);
    }
    
    private void on_extension_added (Peas.ExtensionSet set, Peas.PluginInfo info, Peas.Extension extension) {
        foreach (var plugin in engine.get_plugin_list ()) {
            string module = plugin.get_module_name ();
            if (module == info.get_module_name ()) {
                ((Peas.Activatable)extension).activate();
            }
        }
    }

    private void on_extension_removed (Peas.PluginInfo info, Object extension) {
        ((Peas.Activatable) extension).deactivate ();
    }
    
    public void register_plug (Switchboard.Plug plug) {
        if (plugs.contains (plug) == false) {
            plugs.add (plug);
            plug_added (plug);
        }
    }
}
