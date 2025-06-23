switchboard_files = files(
    'Application.vala',
    'PlugsSearch.vala',
    'CategoryView.vala',
    'MainWindow.vala',
    'SearchView.vala',
    'Widgets/CategoryIcon.vala',
    'Widgets/CategoryFlowBox.vala',
)

switchboard_deps = [
    adwaita_dep,
    libswitchboard_dep,
    granite_dep,
    pantheon_wayland_dep,
    m_dep
]

executable(meson.project_name(),
    stylesheet_resource,
    switchboard_files,
    conf_file,
    dependencies: switchboard_deps,
    install: true
)
