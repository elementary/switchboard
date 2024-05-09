project(
    'io.elementary.settings',
    'c', 'vala',
    version: '8.0.0',
)

lib_version = '2.0'

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DG_LOG_DOMAIN="switchboard"'
    ],
    language: 'c'
)

conf_data = configuration_data()
conf_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: conf_data
)

plugs_dir = get_option('prefix') / get_option('libdir') / 'switchboard-3'

gnome = import('gnome')
i18n = import('i18n')
pkg = import('pkgconfig')

glib_dep = dependency('glib-2.0', version: '>=2.32')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gmodule_dep = dependency('gmodule-2.0')
gtk_dep = dependency('gtk4', version: '>=3.10')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite-7', version: '>=7.0.0')
adwaita_dep = dependency('libadwaita-1', version: '>=1.4')
m_dep = meson.get_compiler('c').find_library('m', required : false)

subdir('data')
subdir('lib')
subdir('src')
if get_option('example')
    subdir('sample')
endif
subdir('po')

meson.add_install_script('meson/post_install.py')
