#! /usr/bin/env python
# encoding: utf-8
# Copyright (c) 2010: GPL
# Author: SjB <steve@sagacity.ca>
#

VERSION = '0.5'
APPNAME = 'Switchboard'

top = '.'
out = '_build_'

def options(opt):
    opt.load('compiler_c')
    opt.load('vala')

def configure(conf):
    conf.load('compiler_c vala')
    conf.check_vala(min_version=(0,12,0))

    conf.check_cfg(package = 'glib-2.0',
            uselib_store = 'GLIB',
            atleast_version = '2.22.0',
            mandatory = 1,
            args = '--cflags --libs')

    conf.check_cfg(package = 'gtk+-2.0',
            uselib_store = 'GTK+',
            atleast_version = '2.22.0',
            mandatory = 1,
            args = '--cflags --libs')

    conf.check_cfg(package = 'gee-1.0',
            uselib_store = 'GEE',
            atleast_version = '0.5.3',
            args = '--cflags --libs')
                
    conf.check_cfg(package = 'unique-1.0',
            uselib_store = 'UNIQUE',
            atleast_version = '1.1.0',
            args = '--cflags --libs')

    conf.define ('GETTEXT_PACKAGE', APPNAME)

def build(bld):
    # Build main program
    src = [ 'Switchboard.vala',
            'ElementaryEntry.vala',
            'log.vala',
            'AppMenu.vala',
            'CategoryView.vala'
          ]

    bld.program(target = 'switchboard',
            packages = 'glib-2.0 gee-1.0 gtk+-2.0 unique-1.0',
            uselib = 'GLIB GTK+ GEE UNIQUE',
            source = src);

