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

    local BASE_DIR="${BUILD_DIR}/astra-gtksdk"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase --include="apt-utils,locales,ca-certificates" 1.8_x86-64  "${BASE_DIR}"     https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_chroot "${BASE_DIR}"
}

configure_chroot() {
    local BASE_DIR="$1"
    log "Configuring system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash
set -e
echo "deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware
deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware" | tee /etc/apt/sources.list
apt update
apt install -y libarchive13 libcurl4 libexpat1 libuv1 procps
apt install -y cmake gcc g++
apt install -y libapt-pkg-dev libc-dev libglib2.0-dev libgtk-3-dev libgtk-4-dev libjpeg-dev libpng-dev libtiff-dev libstdc++-12-dev libgirepository1.0-dev libgtksourceview-4-dev
apt-get install -y \
    build-essential \
    cmake \
    gcc \
    g++ \
    git \
    ninja-build \
    pkg-config \
    meson \
    libgtk-3-dev \
    libgtk-4-dev \
    libgtk2.0-dev \
    libglib2.0-dev \
    libgirepository1.0-dev \
    libgtksourceview-4-dev \
    glade \
    gtk-doc-tools \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libcairo2-dev \
    libpango1.0-dev \
    librsvg2-dev \
    gobject-introspection \
    libgirepository1.0-dev \
    gir1.2-gtk-3.0 \
    gir1.2-gtk-4.0 \
    devhelp \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libsoup2.4-dev \
    libwebkit2gtk-4.0-dev \
    libnotify-dev \
    libvte-2.91-dev \
    libxml2-dev \
    libcanberra-gtk3-dev \
    python3-dev \
    python3-gi \
    python3-gi-cairo \
    gdb \
    valgrind \
    devhelp-common \
    libgtk-3-doc \
    libgtk-4-doc \
    libglib2.0-doc \
    gettext \
    intltool \
    libxml2-utils \
    xsltproc

apt-get clean

EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."

    local BASE_DIR="${BUILD_DIR}/astra-gtksdk"
    local ARCHIVE_NAME="astra-gtksdk.tar.gz"

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
        "${BUILD_DIR}/build-dir2" \
        "${MANIFEST_DIR}/org.astra.gtkSdk.json" \
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
