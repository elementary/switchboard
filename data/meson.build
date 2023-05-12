po_extra_dir = join_paths(meson.source_root(), 'po', 'extra')
i18n.merge_file(
    input: 'io.elementary.switchboard.desktop.in',
    output: 'io.elementary.switchboard.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: po_extra_dir,
    type: 'desktop'
)

i18n.merge_file(
    input: 'io.elementary.switchboard.appdata.xml.in',
    output: 'io.elementary.switchboard.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: po_extra_dir
)

install_data(
    'io.elementary.switchboard.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

icon_sizes = ['24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach
