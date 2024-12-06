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

    local BASE_DIR="${BUILD_DIR}/astra-qt"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase --include="apt-utils,locales,ca-certificates" 1.8_x86-64  "${BASE_DIR}"     https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_chroot "${BASE_DIR}"
}

configure_chroot() {
    local BASE_DIR="$1"
    log "Configuring system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash
set -e
apt update
apt-get install -y \
    fly-all-main \
    alsa-utils \
    plymouth-x11 \
    breeze-gtk-theme \
    python3-reportlab \
    fontconfig-config \
    printer-driver-postscript-hp \
    hpijs-ppds \
    fontconfig \
    avahi-daemon \
    desktop-base \
    fly-admin-kiosk \
    ksystemlog \
    plymouth \
    hplip-gui \
    acpi-support \
    fly-astra-update \
    network-manager-gnome \
    synaptic \
    fly-all-optional \
    fly-admin-int-check \
    menu \
    xorg-all-main \
    eject \
    anacron \
    qtvirtualkeyboard-plugin \
    cups \
    system-config-audit \
    phonon4qt5-backend-gstreamer \
    libmtp-runtime \
    cups-client \
    network-manager-openvpn-gnome \
    printer-driver-hpcups \
    astra-extra \
    cups-pk-helper \
    fly-admin-marker \
    printer-driver-hpijs \
    dbus-x11 \
    plymouth-astra-theme \
    hplip \
    pulseaudio \
    qt5-style-plugins \
    qt5-gtk-platformtheme
apt-get clean

EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."

    local BASE_DIR="${BUILD_DIR}/astra-qt"
    local ARCHIVE_NAME="astra-qt.tar.gz"

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
        "${BUILD_DIR}/build-dir4" \
        "${MANIFEST_DIR}/org.astra.qt.json" \
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
