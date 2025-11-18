po_extra_dir = join_paths(meson.source_root(), 'po', 'extra')

install_data(
    'settings.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
    rename: meson.project_name() + '.gschema.xml'
)

configure_file(
    input: 'settings.service.in',
    output: meson.project_name() + '.service',
    configuration: conf_data,
    install_dir: get_option('datadir') / 'dbus-1' / 'services',
    install: true
)

i18n.merge_file(
    input: 'settings.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: po_extra_dir,
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

i18n.merge_file(
    input: 'settings.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: po_extra_dir,
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
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

subdir('styles')
