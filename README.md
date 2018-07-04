# Switchboard
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/?utm_source=widget)

![System Settings Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:

* cmake
* debhelper
* libclutter-gtk-1.0-dev
* libgee-0.8-dev
* libglib2.0-dev
* libgranite-dev
* libgtk-3-dev
* libunity-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard

