config_vapi = meson.get_compiler('vala').find_library('config', dirs: meson.current_source_dir())

config_data = configuration_data()
config_data.set_quoted('PLUGS_DIR', plugs_dir)

config_header = configure_file(
    configuration: config_data,
    output: 'config.h'
)

libswitchboard_deps = [
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gmodule_dep,
    gee_dep,
    gtk_dep,
]

libswitchboard_lib = shared_library('switchboard-2.0',
    'PlugsManager.vala',
    'Plug.vala',
    config_header,
    dependencies: [libswitchboard_deps, config_vapi],
    vala_header: 'switchboard.h',
    soversion: '0',
    version: lib_version,
    install: true,
    install_dir: [true, join_paths(get_option('includedir'), 'switchboard-2.0'), true]
)

pkg.generate(
    filebase: 'switchboard-2.0',
    name: 'Switchboard',
    description: 'Switchboard Settings API',
    version: meson.project_version(),
    subdirs: 'switchboard-2.0',
    variables: ['plugsdir=${libdir}/switchboard'],
    libraries: libswitchboard_lib,
    requires: libswitchboard_deps
)

install_data(
    'switchboard-2.0.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

libswitchboard_dir = include_directories('.')
libswitchboard_dep = declare_dependency(
    link_with: libswitchboard_lib,
    dependencies: [libswitchboard_deps, config_vapi],
    include_directories: libswitchboard_dir
)
