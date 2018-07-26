project(
    'switchboard',
    'c', 'vala',
    version: '2.3.1',
)

lib_version = '2.0'

add_project_arguments([
        '-DGETTEXT_PACKAGE="switchboard"',
        '-DG_LOG_DOMAIN="switchboard"'
    ],
    language: 'c'
)

plugs_dir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name())

i18n = import('i18n')
pkg = import('pkgconfig')

glib_dep = dependency('glib-2.0', version: '>=2.32')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gmodule_dep = dependency('gmodule-2.0')
gtk_dep = dependency('gtk+-3.0', version: '>=3.10')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite')
m_dep = meson.get_compiler('c').find_library('m', required : false)
libunity_dep = []
if get_option('libunity')
    libunity_dep = dependency('unity')
    add_project_arguments('--define=HAVE_UNITY', language: 'vala')
endif

subdir('data')
subdir('lib')
subdir('src')
if get_option('example')
    subdir('sample')
endif
subdir('po')

meson.add_install_script('meson/post_install.py')
