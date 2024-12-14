#!/bin/bash

# Определение директорий
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_dir"
MANIFEST_DIR="${SCRIPT_DIR}/manifests"
REPO_DIR="${SCRIPT_DIR}/repo"
RUNTIME_DIR="${BUILD_DIR}/runtime"
SDK_DIR="${BUILD_DIR}/sdk"
PLATFORM_ID="org.astra.Gtk"
SDK_ID="org.astra.gtkSdk"
ARCH="x86_64"
VERSION="1.8"

# Функции логирования и обработки ошибок
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

handle_error() {
    log "Error: $1"
    exit 1
}

# Создание структуры директорий
verify_structure() {
    log "Verifying project structure..."
    for dir in "$BUILD_DIR" "$MANIFEST_DIR" "$REPO_DIR" "$RUNTIME_DIR" "$SDK_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || handle_error "Failed to create directory: $dir"
        fi
    done
}

# Создаем базовую runtime систему
create_base_runtime() {
    log "Creating base runtime system..."
    local BASE_DIR="${BUILD_DIR}/astra-gtk-base"

    # Проверяем наличие базовой системы
    if [ -d "${BASE_DIR}" ] && [ -d "${BASE_DIR}/usr" ] && [ -d "${BASE_DIR}/etc" ]; then
        log "Base runtime system already exists, skipping debootstrap..."
        return 0
    fi

    # Очищаем если существует но неполная
    [ -d "${BASE_DIR}" ] && sudo rm -rf "${BASE_DIR}"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase \
        --include="apt-utils,locales,ca-certificates" \
        1.8_x86-64 "${BASE_DIR}" \
        https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_runtime_chroot "${BASE_DIR}"
}

configure_runtime_chroot() {
    local BASE_DIR="$1"
    log "Configuring runtime system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash

# Установка базовых GTK пакетов и зависимостей
set -e
apt-get update
apt install -y bubblewrap desktop-file-utils evolution evolution-common evolution-data-server gimp gimp-data graphviz gsettings-desktop-schemas gvfs hicolor-icon-theme libaa1 libapt-pkg6.0 libbabl-0.1-0 libbz2-1.0 libc6 libcairo2 libcamel-1.2-64 libcloudproviders0 libecal-2.0-2 libedataserver-1.2-27 libept1.6.0 libevolution libfontconfig1 libfreetype6 libgcc-s1 libgdk-pixbuf-2.0-0 libgegl-0.4-0 libgexiv2-2 libgimp2.0 libglib2.0-0 libglib2.0-data libgnome-autoar-0-0 libgs10 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libgtk-3-0 libgtk-4-1 libgtk2.0-0 libharfbuzz0b libheif1 libical3 libjpeg62-turbo libjson-glib-1.0-0 libjxl0.7 liblcms2-2 liblzma5 libmng1 libmypaint-1.5-1 libnotify4 libopenexr-3-1-30 libopenjp2-7 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpng16-16 libpoppler-glib8 libselinux1 libstdc++6 libtiff6 libvte-2.91-0 libwebp7 libwebpdemux2 libwebpmux3 libwmf-0.2-7 libwmflite-0.2-7 libx11-6 libxapian30 libxcursor1 libxext6 libxfixes3 libxml2 libxmu6 libxpm4 pkexec policykit-1 polkitd psmisc shared-mime-info synaptic libglib2.0-0
apt install -y \
    glib-networking \
    gsettings-desktop-schemas \
    adwaita-icon-theme \
    librsvg2-common \
    xdg-desktop-portal-gtk \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libsoup2.4-1 \
    libsecret-1-0 \
    libwebkit2gtk-4.0-37
apt-get install -y \
    bubblewrap \
    desktop-file-utils \
    gsettings-desktop-schemas \
    gvfs \
    hicolor-icon-theme \
    shared-mime-info \
    libgtk-3-0 \
    libgtk-4-1 \
    libgtk2.0-0 \
    libglib2.0-0 \
    libglib2.0-data \
    glib-networking \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    adwaita-icon-theme \
    librsvg2-common \
    libgdk-pixbuf-2.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libpng16-16 \
    libjpeg62-turbo \
    libtiff6 \
    libwebp7 \
    libwebpdemux2 \
    libwebpmux3 \
    xdg-desktop-portal-gtk \
    libsoup2.4-1 \
    libsecret-1-0 \
    libwebkit2gtk-4.0-37 \
    pkexec \
    policykit-1 \
    polkitd \
    libnotify4 \
    libxml2 \
    libselinux1 \
    libvte-2.91-0 \
    libaa1 \
    libbz2-1.0 \
    libharfbuzz0b \
    libfontconfig1 \
    libfreetype6 \
    libx11-6 \
    libxcursor1 \
    libxext6 \
    libxfixes3 \
    libxmu6 \
    libxpm4
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

# Создаем базовую SDK систему
create_base_sdk() {
    log "Creating base SDK system..."
    local BASE_DIR="${BUILD_DIR}/astra-gtk-sdk"

    # Проверяем наличие базовой системы SDK
    if [ -d "${BASE_DIR}" ] && [ -d "${BASE_DIR}/usr" ] && [ -d "${BASE_DIR}/etc" ]; then
        log "Base SDK system already exists, skipping debootstrap..."
        return 0
    fi

    # Очищаем если существует но неполная
    [ -d "${BASE_DIR}" ] && sudo rm -rf "${BASE_DIR}"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase \
        --include="apt-utils,locales,ca-certificates" \
        1.8_x86-64 "${BASE_DIR}" \
        https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/ || handle_error "Debootstrap failed"

    configure_sdk_chroot "${BASE_DIR}"
}

configure_sdk_chroot() {
    local BASE_DIR="$1"
    log "Configuring SDK system in chroot..."

    cat << 'EOF' | sudo chroot "${BASE_DIR}" /bin/bash
set -e
# Добавляем репозитории
cat > /etc/apt/sources.list << REPOS
deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware
deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware
REPOS

apt-get update

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
    xsltproc \
    python3-venv \
    python3-pip 

# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."
    local BASE_DIR="${BUILD_DIR}/astra-gtk-base"
    local TEMP_DIR="${BUILD_DIR}/runtime-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy runtime system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-gtk-runtime.tar.gz" \
        --exclude='dev/*' --exclude='proc/*' --exclude='sys/*' --exclude='run/*' \
        --exclude='tmp/*' --owner=root --group=root .) || handle_error "Failed to create runtime archive"

    sudo rm -rf "${TEMP_DIR}"
}

create_sdk_archive() {
    log "Creating SDK archive..."
    local BASE_DIR="${BUILD_DIR}/astra-gtk-sdk"
    local TEMP_DIR="${BUILD_DIR}/sdk-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy SDK system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-gtk-sdk.tar.gz" \
        --exclude='dev/*' --exclude='proc/*' --exclude='sys/*' --exclude='run/*' \
        --exclude='tmp/*' --owner=root --group=root .) || handle_error "Failed to create SDK archive"

    sudo rm -rf "${TEMP_DIR}"
}

create_flatpak_runtime() {
    log "Creating Flatpak runtime structure..."

    rm -rf "${RUNTIME_DIR}"/*
    mkdir -p "${RUNTIME_DIR}/usr"
    mkdir -p "${RUNTIME_DIR}/files/"{dev,proc,sys}

    # Распаковываем систему в usr
    tar xzf "${BUILD_DIR}/astra-gtk-runtime.tar.gz" -C "${RUNTIME_DIR}/usr/" || \
        handle_error "Failed to extract runtime archive"

    cat > "${RUNTIME_DIR}/metadata" << EOF
[Runtime]
name=${PLATFORM_ID}
arch=${ARCH}
branch=${VERSION}

[Environment]
PATH=/app/bin:/usr/bin:/bin
XDG_DATA_DIRS=/app/share:/usr/share:/usr/share/runtime/share:/run/host/share
EOF
}

create_flatpak_sdk() {
    log "Creating Flatpak SDK structure..."

    rm -rf "${SDK_DIR}"/*
    mkdir -p "${SDK_DIR}/usr"
    mkdir -p "${SDK_DIR}/files/"{dev,proc,sys}

    # Распаковываем систему в usr
    tar xzf "${BUILD_DIR}/astra-gtk-sdk.tar.gz" -C "${SDK_DIR}/usr/" || \
        handle_error "Failed to extract SDK archive"

    cat > "${SDK_DIR}/metadata" << EOF
[Runtime]
name=${SDK_ID}
arch=${ARCH}
branch=${VERSION}
runtime=${PLATFORM_ID}/${ARCH}/${VERSION}

[Environment]
PATH=/app/bin:/usr/bin:/bin
XDG_DATA_DIRS=/app/share:/usr/share:/usr/share/runtime/share:/run/host/share

[Extension ${SDK_ID}]
directory=usr
version=${VERSION}
EOF
}

initialize_repo() {
    log "Initializing Flatpak repository..."

    if [ ! -f "${REPO_DIR}/config" ]; then
        ostree init --mode=archive-z2 --repo="${REPO_DIR}" || handle_error "Failed to initialize repository"
    fi
}

commit_to_repo() {
    log "Committing runtime and SDK to repository..."

    # Коммит runtime в OSTree
    ostree --repo="${REPO_DIR}" commit \
        --branch="${PLATFORM_ID}" \
        --subject="Astra GTK Runtime ${VERSION}" \
        --body="Based on Astra Linux" \
        "${RUNTIME_DIR}/usr" || handle_error "Failed to commit runtime to repository"

    # Коммит SDK в OSTree
    ostree --repo="${REPO_DIR}" commit \
        --branch="${SDK_ID}" \
        --subject="Astra GTK SDK ${VERSION}" \
        --body="Based on Astra Linux" \
        "${SDK_DIR}/usr" || handle_error "Failed to commit SDK to repository"

    # Экспорт runtime в Flatpak
    flatpak build-export \
        "${REPO_DIR}" \
        "${RUNTIME_DIR}" \
        "${VERSION}" || handle_error "Failed to export runtime"

    # Экспорт SDK в Flatpak
    flatpak build-export \
        "${REPO_DIR}" \
        "${SDK_DIR}" \
        "${VERSION}" || handle_error "Failed to export SDK"

    # Обновляем summary
    flatpak build-update-repo "${REPO_DIR}" || handle_error "Failed to update repository summary"
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${BUILD_DIR}"

}

print_instructions() {
    cat << EOF

Repository created successfully!

To use this repository:

1. Add repository on client:
   flatpak remote-add astra-gtk-repo ${REPO_DIR}

2. Install runtime and SDK:
   flatpak install astra-gtk-repo ${PLATFORM_ID}
   flatpak install astra-gtk-repo ${SDK_ID}

The repository is located at: ${REPO_DIR}

EOF
}

main() {
    log "Starting Astra GTK Platform build..."

    verify_structure
    
    # Создание runtime
    create_base_runtime
    create_runtime_archive
    create_flatpak_runtime
    
    # Создание SDK
    create_base_sdk
    create_sdk_archive
    create_flatpak_sdk
    
    # Инициализация и наполнение репозитория
    initialize_repo
    commit_to_repo
    cleanup

    log "Build completed successfully"
    print_instructions
}

# Запуск скрипта
main "$@" || handle_error "Build process failed"
