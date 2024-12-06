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

    local BASE_DIR="${BUILD_DIR}/astra-qtsdk"
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
apt-get install -y \
    qtbase5-dev \
    qt5-qmake \
    libx11-dev \
    libxcb1-dev \
    libxkbcommon-dev \
    libxext-dev \
    libxi-dev \
    libxtst-dev \
    libasound2-dev \
    libpulse-dev \
    libsndfile1-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    mesa-common-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libcairo2-dev \
    libdbus-1-dev \
    libdbus-glib-1-dev \
    libsystemd-dev \
    python3-dev \
    python3-all-dev \
    libcups2-dev \
    libcupsimage2-dev \
    libnm-dev \
    libndp-dev \
    libnl-3-dev \
    extra-cmake-modules \
    libkf5config-dev \
    libkf5coreaddons-dev \
    libkf5i18n-dev \
    libkf5kio-dev \
    libkf5service-dev \
    libkf5windowsystem-dev \
    qttools5-dev \
    qttools5-dev-tools
apt-get clean

EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."

    local BASE_DIR="${BUILD_DIR}/astra-qtsdk"
    local ARCHIVE_NAME="astra-qtsdk.tar.gz"

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
        "${BUILD_DIR}/build-dir5" \
        "${MANIFEST_DIR}/org.astra.qtSdk.json" \
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
