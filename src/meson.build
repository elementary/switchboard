switchboard_files = files(
    'Application.vala',
    'PlugsSearch.vala',
    'CategoryView.vala',
    'SearchView.vala',
    'Widgets/CategoryIcon.vala',
    'Widgets/CategoryFlowBox.vala',
)

switchboard_deps = [
    libswitchboard_dep,
    granite_dep,
    adwaita_dep,
    m_dep
]

executable(meson.project_name(),
    stylesheet_resource,
    switchboard_files,
    conf_file,
    dependencies: switchboard_deps,
    install: true
)
