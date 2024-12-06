#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build_dir"
MANIFEST_DIR="${PROJECT_ROOT}/manifests"
REPO_DIR="${PROJECT_ROOT}/repo"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

handle_error() {
    log "Error: $1"
    exit 1
}

verify_structure() {
    log "Verifying project structure..."

    for dir in "$BUILD_DIR" "$MANIFEST_DIR" "$REPO_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || handle_error "Failed to create directory: $dir"
        fi
    done
}


create_base_system() {
    log "Creating base system..."

    local BASE_DIR="${BUILD_DIR}/astra-gtk"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase --include="apt-utils,locales,ca-certificates" 1.8_x86-64  "${BASE_DIR}"     https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_chroot "${BASE_DIR}"
}

configure_chroot() {
    local BASE_DIR="$1"
    log "Configuring system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash
set -e
apt-get update
apt install -y bubblewrap desktop-file-utils evolution evolution-common evolution-data-server gimp gimp-data graphviz gsettings-desktop-schemas gvfs hicolor-icon-theme libaa1 libapt-pkg6.0 libbabl-0.1-0 libbz2-1.0 libc6 libcairo2 libcamel-1.2-64 libcloudproviders0 libecal-2.0-2 libedataserver-1.2-27 libept1.6.0 libevolution libfontconfig1 libfreetype6 libgcc-s1 libgdk-pixbuf-2.0-0 libgegl-0.4-0 libgexiv2-2 libgimp2.0 libglib2.0-0 libglib2.0-data libgnome-autoar-0-0 libgs10 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libgtk-3-0 libgtk-4-1 libgtk2.0-0 libharfbuzz0b libheif1 libical3 libjpeg62-turbo libjson-glib-1.0-0 libjxl0.7 liblcms2-2 liblzma5 libmng1 libmypaint-1.5-1 libnotify4 libopenexr-3-1-30 libopenjp2-7 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpng16-16 libpoppler-glib8 libselinux1 libstdc++6 libtiff6 libvte-2.91-0 libwebp7 libwebpdemux2 libwebpmux3 libwmf-0.2-7 libwmflite-0.2-7 libx11-6 libxapian30 libxcursor1 libxext6 libxfixes3 libxml2 libxmu6 libxpm4 pkexec policykit-1 polkitd psmisc shared-mime-info synaptic libglib2.0-0
apt install -y \
    glib-networking \
    gsettings-desktop-schemas \
    adwaita-icon-theme \
    librsvg2-common \
    gvfs-backends \
    xdg-desktop-portal-gtk \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libsoup2.4-1 \
    libsecret-1-0 \
    libwebkit2gtk-4.0-37
apt-get clean

EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."

    local BASE_DIR="${BUILD_DIR}/astra-gtk"
    local ARCHIVE_NAME="astra-gtk.tar.gz"

    sudo tar czf "${BUILD_DIR}/${ARCHIVE_NAME}" \
        --exclude='dev/*' \
        --exclude='proc/*' \
        --exclude='sys/*' \
        --exclude='run/*' \
        --exclude='tmp/*' \
        --preserve-permissions \
        -C "${BASE_DIR}" . \
        || handle_error "Failed to create archive"
}

build_runtime() {
    log "Building Flatpak runtime..."

    flatpak-builder \
        --repo="${REPO_DIR}" \
        --force-clean \
        "${BUILD_DIR}/build-dir1" \
        "${MANIFEST_DIR}/org.astra.gtk.json" \
        || handle_error "Flatpak build failed"
}

main() {
    log "Starting Astra Main Platform build..."
    verify_structure
    create_base_system
    create_runtime_archive
    build_runtime

    log "Build completed successfully"
}

main "$@" || handle_error "Build process failed"
