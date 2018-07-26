po_extra_dir = join_paths(meson.source_root(), 'po', 'extra')
i18n.merge_file('desktop',
    input: 'io.elementary.switchboard.desktop.in',
    output: 'io.elementary.switchboard.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: po_extra_dir,
    type: 'desktop'
)

i18n.merge_file('appdata',
    input: 'io.elementary.switchboard.appdata.xml.in',
    output: 'io.elementary.switchboard.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: po_extra_dir
)

install_data(
    '../schemas/io.elementary.switchboard.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
