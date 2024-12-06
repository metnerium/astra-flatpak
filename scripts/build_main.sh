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

    local BASE_DIR="${BUILD_DIR}/astra-base"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase --include="apt-utils,locales,ca-certificates,dbus,systemd,bash,coreutils,util-linux,findutils,grep,gawk,sed" 1.8_x86-64  "${BASE_DIR}"     https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_chroot "${BASE_DIR}"
}

configure_chroot() {
    local BASE_DIR="$1"
    log "Configuring system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash
set -e
apt-get update
apt-get install -y \
    tzdata \
    openssl \
    ca-certificates \
    zlib1g \
    bzip2 \
    xz-utils \
    lz4 \
    p7zip-full \
    openprinting-ppds \
    libgutenprint9 \
    aspell-en \
    hunspell-ru \
    unrar \
    libparsec-cap3 \
    apt \
    atftp \
    dvd+rw-tools \
    vim \
    sosreport \
    anacron \
    libparsec-base3 \
    p7zip-rar \
    libparsec-mac3 \
    util-linux-locales \
    snmp \
    parsec-tools \
    quota \
    mc \
    less \
    gostsum \
    manpages-ru \
    acpid \
    apt-utils \
    libijs-0.35 \
    wpasupplicant \
    libparsec-aud3 \
    mueller7-dict \
    ntfs-3g \
    apt-transport-https \
    openssh-client \
    acpi \
    rsh-client \
    bsign \
    sudo \
    parsec-cap \
    parsec-aud \
    expect \
    astra-update \
    powertop \
    systemd-timesyncd \
    parsec-mac \
    gutenprint-locales \
    afick \
    parsec-base \
    pcmciautils \
    unzip \
    parsec-kiosk2 \
    logcheck \
    bind9-host \
    ncurses-term \
    aspell-ru \
    wireless-tools \
    dosfstools \
    bash-completion \
    parsec-cups \
    fakeroot \
    lsof \
    linux-firmware

apt-get clean

EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."

    local BASE_DIR="${BUILD_DIR}/astra-base"
    local ARCHIVE_NAME="astra-mainPlatform.tar.gz"

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
        "${BUILD_DIR}/build-dir" \
        "${MANIFEST_DIR}/org.astra.mainPlatform.json" \
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
