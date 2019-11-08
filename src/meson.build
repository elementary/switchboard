switchboard_files = files(
    'Application.vala',
    'PlugsSearch.vala',
    'CategoryView.vala',
    'Widgets/CategoryIcon.vala',
    'Widgets/CategoryFlowBox.vala',
)

switchboard_deps = [
    libswitchboard_dep,
    clutter_gtk_dep,
    granite_dep,
    handy_dep,
    m_dep
]

executable(meson.project_name(),
    switchboard_files,
    dependencies: switchboard_deps,
    install: true
)
