# Switchboard
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard.svg)](https://repology.org/metapackage/switchboard)
[![l10n](https://l10n.elementary.io/widgets/switchboard/-/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/?utm_source=widget)

![System Settings Screenshot](data/screenshot.png?raw=true)

## Plugs

Switchboard is just the container application for Switchboard Plugs, which provide the actual settings for various hardware and software.

[Browse all Plugs](https://github.com/elementary?q=switchboard-plug)

## Building, Testing, and Installation

You'll need the following dependencies:

* libclutter-gtk-1.0-dev
* libgee-0.8-dev
* libglib2.0-dev
* libgranite-dev
* libgtk-3-dev
* libunity-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install` then execute with `switchboard`

    sudo ninja install
    switchboard

## Making Switchboard Plugs

Documentation for LibSwitchboard is available [on Valadoc.org](https://valadoc.org/switchboard-2.0/Switchboard.Plug.html)
