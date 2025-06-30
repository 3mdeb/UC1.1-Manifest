#!/bin/bash
set -e

REQUIRED_TIO_VERSION="3.8"
TIO_SOURCE_URL="https://github.com/tio/tio/releases/download/v3.8/tio-3.8.tar.xz"

function check_os_fedora() {
    if [[ -f /etc/fedora-release ]]; then
        return 0
    else
        return 1
    fi
}

function tio_version() {
    if ! command -v tio &>/dev/null; then
        echo ""
        return 1
    fi
    # Extract version string e.g. "tio v3.8" or "tio v3.9"
    local ver
    ver=$(tio --version 2>&1 | head -n1 | grep -oP '\K[0-9]+\.[0-9]+')
    echo "$ver"
}

function uninstall_tio_dnf() {
    echo "Uninstalling existing tio package via dnf..."
    sudo dnf remove -y tio
}

function install_build_deps() {
    echo "Installing build dependencies..."
    sudo dnf install -y gcc gcc-c++ make meson ninja-build glib2-devel systemd-devel wget tar xz lua lua-devel
}

function build_and_install_tio() {
    echo "Downloading tio $REQUIRED_TIO_VERSION source..."
    tmpdir=$(mktemp -d)
    pushd "$tmpdir"
    wget -q "$TIO_SOURCE_URL" -O tio.tar.xz
    tar -xf tio.tar.xz
    cd tio-3.8

    echo "Building tio $REQUIRED_TIO_VERSION..."
    meson setup build
    ninja -C build
    sudo ninja -C build install

    popd
    rm -rf "$tmpdir"
}

# Main logic

current_version=$(tio_version)
if [[ "$current_version" == "$REQUIRED_TIO_VERSION" ]]; then
    echo "tio $REQUIRED_TIO_VERSION is already installed."
    exit 0
fi

if ! check_os_fedora; then
    echo "This script only handles Fedora for installation."
    if [[ -z "$current_version" ]]; then
        echo "tio $REQUIRED_TIO_VERSION is not installed. Exiting."
        exit 1
    else
        echo "But tio version $current_version is already installed, exiting."
        exit 0
    fi
fi

# Now we know OS is Fedora, and tio 3.8 is not installed
if [[ -n "$current_version" ]]; then
    echo "Detected tio version $current_version installed via package manager or other means."
    uninstall_tio_dnf
fi

install_build_deps
build_and_install_tio

# Verify install success
new_version=$(tio_version)
if [[ "$new_version" == "$REQUIRED_TIO_VERSION" ]]; then
    echo "tio $REQUIRED_TIO_VERSION installed successfully."
    exit 0
else
    echo "Failed to install tio $REQUIRED_TIO_VERSION."
    exit 2
fi
