# System Settings
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard.svg)](https://repology.org/metapackage/switchboard)
[![Translation status](https://l10n.elementaryos.org/widget/settings/settings/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![System Settings Screenshot](data/screenshot.png?raw=true)

## Plugins

System Settings is the container application for Switchboard Plugs, which provide the actual settings for various hardware and software.

[Browse all Plugins](https://github.com/elementary?q=settings#org-repositories)

## Building, Testing, and Installation

You'll need the following dependencies:

* libgee-0.8-dev
* libglib2.0-dev (>= 2.76)
* libgranite-7-dev
* libgtk-4-dev
* libadwaita-1-dev (>= 1.4)
* meson (>= 0.57.0)
* sassc
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install` then execute with `io.elementary.settings`

    sudo ninja install
    io.elementary.settings

## Making Settings Plugins

Documentation for LibSwitchboard is available [on Valadoc.org](https://valadoc.org/switchboard-2.0/Switchboard.Plug.html)
