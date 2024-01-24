config_vapi = meson.get_compiler('vala').find_library('config', dirs: meson.current_source_dir())

config_data = configuration_data()
config_data.set_quoted('PLUGS_DIR', plugs_dir)

config_header = configure_file(
    configuration: config_data,
    output: 'config.h'
)

libswitchboard_deps = [
    adwaita_dep,
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gmodule_dep,
    gee_dep,
    granite_dep,
    gtk_dep,
]

libswitchboard_lib = library('switchboard-3',
    'AbstractSettingsPage.vala',
    'AbstractSimpleSettingsPage.vala',
    'PlugsManager.vala',
    'Plug.vala',
    'SettingsSidebarRow.vala',
    'SettingsSidebar.vala',
    config_header,
    dependencies: [libswitchboard_deps, config_vapi],
    vala_header: 'switchboard.h',
    soversion: '0',
    version: lib_version,
    install: true,
    install_dir: [true, join_paths(get_option('includedir'), 'switchboard-3'), true]
)

pkg.generate(
    filebase: 'switchboard-3',
    name: 'Switchboard',
    description: 'Switchboard Settings API',
    version: meson.project_version(),
    subdirs: 'switchboard-3',
    variables: ['plugsdir=${libdir}/switchboard-3'],
    libraries: libswitchboard_lib,
    requires: libswitchboard_deps
)

install_data(
    'switchboard-3.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

libswitchboard_dir = include_directories('.')
libswitchboard_dep = declare_dependency(
    link_with: libswitchboard_lib,
    dependencies: [libswitchboard_deps, config_vapi],
    include_directories: libswitchboard_dir
)
