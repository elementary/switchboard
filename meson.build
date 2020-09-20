project(
    'io.elementary.switchboard',
    'c', 'vala',
    version: '2.4.0',
)

lib_version = '2.0'

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DG_LOG_DOMAIN="switchboard"',
        '-DHANDY_USE_UNSTABLE_API',
    ],
    language: 'c'
)

plugs_dir = join_paths(get_option('prefix'), get_option('libdir'), 'switchboard')

i18n = import('i18n')
pkg = import('pkgconfig')

glib_dep = dependency('glib-2.0', version: '>=2.32')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gmodule_dep = dependency('gmodule-2.0')
gtk_dep = dependency('gtk+-3.0', version: '>=3.10')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite', version: '>=5.4.0')
handy_dep = dependency('libhandy-1', version: '>=0.83.0')
m_dep = meson.get_compiler('c').find_library('m', required : false)

subdir('data')
subdir('lib')
subdir('src')
if get_option('example')
    subdir('sample')
endif
subdir('po')

meson.add_install_script('meson/post_install.py')
