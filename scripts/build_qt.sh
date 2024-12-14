#!/bin/bash

# Определение директорий
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_dir"
MANIFEST_DIR="${SCRIPT_DIR}/manifests"
REPO_DIR="${SCRIPT_DIR}/repo"
RUNTIME_DIR="${BUILD_DIR}/runtime"
SDK_DIR="${BUILD_DIR}/sdk"
PLATFORM_ID="org.astra.Qt"
SDK_ID="org.astra.qtSdk"
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
    local BASE_DIR="${BUILD_DIR}/astra-qt-base"

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
set -e
apt-get update

# Установка базовых Qt пакетов и зависимостей
apt-get install -y \
    fly-all-main \
    alsa-utils \
    plymouth-x11 \
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
    fly-all-optional \
    fly-admin-int-check \
    menu \
    xorg-all-main \
    eject \
    anacron \
    cups \
    system-config-audit \
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
    qt5-gtk-platformtheme \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libqt5network5 \
    libqt5dbus5 \
    libqt5xml5 \
    libqt5sql5 \
    libqt5printsupport5 \
    libqt5multimedia5 \
    libqt5multimedia5-plugins \
    libqt5multimediawidgets5 \
    libqt5positioning5 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5webchannel5 \
    libqt5webkit5 \
    libqt5x11extras5 \
    libkf5coreaddons5 \
    libkf5windowsystem5 \
    libkf5service5 \
    libkf5notifications5 \
    libkf5iconthemes5 \
    libkf5completion5 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libxcb-xkb1
apt-get install -y \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libqt5network5 \
    libqt5dbus5 \
    libqt5xml5 \
    libqt5sql5 \
    libqt5printsupport5 \
    libqt5multimedia5 \
    libqt5multimedia5-plugins \
    libqt5multimediawidgets5 \
    libqt5positioning5 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5webchannel5 \
    libqt5webkit5 \
    libqt5x11extras5 \
    qt5-style-plugins \
    qt5-gtk-platformtheme \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libfontconfig1 \
    libfreetype6 \
    libgl1-mesa-dri \
    libglib2.0-0
# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

# Создаем базовую SDK систему
create_base_sdk() {
    log "Creating base SDK system..."
    local BASE_DIR="${BUILD_DIR}/astra-qt-sdk"

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

# Установка инструментов разработки и SDK пакетов
apt install -y libarchive13 libcurl4 libexpat1 libuv1 procps
apt-get install -y \
    build-essential \
    cmake \
    gcc \
    g++ \
    git \
    subversion \
    ninja-build \
    pkg-config \
    make \
    autoconf \
    automake \
    libtool \
    qtbase5-dev \
    qt5-qmake \
    qt5-default \
    qttools5-dev \
    qttools5-dev-tools \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qtwebengine5-dev \
    qtpositioning5-dev \
    qtconnectivity5-dev \
    qtlocation5-dev \
    qtscript5-dev \
    qt5-assistant \
    extra-cmake-modules \
    libkf5config-dev \
    libkf5coreaddons-dev \
    libkf5i18n-dev \
    libkf5kio-dev \
    libkf5service-dev \
    libkf5windowsystem-dev \
    libkf5auth-dev \
    libkf5bookmarks-dev \
    libkf5codecs-dev \
    libkf5completion-dev \
    libkf5configwidgets-dev \
    libkf5crash-dev \
    libkf5dbusaddons-dev \
    libkf5declarative-dev \
    libkf5doctools-dev \
    libkf5emoticons-dev \
    libkf5guiaddons-dev \
    libkf5iconthemes-dev \
    libkf5idletime-dev \
    libkf5itemmodels-dev \
    libkf5itemviews-dev \
    libkf5jobwidgets-dev \
    libkf5notifications-dev \
    libkf5parts-dev \
    libkf5plasma-dev \
    libkf5runner-dev \
    libkf5solid-dev \
    libkf5sonnet-dev \
    libkf5textwidgets-dev \
    libkf5wallet-dev \
    libkf5xmlgui-dev \
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
    qttools5-dev \
    qttools5-dev-tools \
    libqt5waylandclient5-dev \
    libqt5waylandcompositor5-dev \
    python3-dev \
    python3-all-dev \
    qtcreator \
    gdb \
    valgrind \
    heaptrack \
    massif-visualizer \
    libboost-all-dev \
    libeigen3-dev \
    libgsl-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libjson-glib-dev \
    libarchive-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libcups2-dev \
    libcupsimage2-dev \
    libnm-dev \
    libndp-dev \
    libnl-3-dev \
    gettext
apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git \
    qtbase5-dev \
    qt5-qmake \
    qt5-default \
    qttools5-dev \
    qttools5-dev-tools \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qtpositioning5-dev \
    qtconnectivity5-dev \
    qtlocation5-dev \
    qtscript5-dev \
    qtwebengine5-dev \
    qt5-assistant \
    extra-cmake-modules \
    libkf5config-dev \
    libkf5coreaddons-dev \
    libkf5i18n-dev \
    libkf5kio-dev \
    libkf5service-dev \
    libkf5windowsystem-dev \
    libkf5auth-dev \
    libkf5codecs-dev \
    libkf5configwidgets-dev \
    libkf5dbusaddons-dev \
    libkf5iconthemes-dev \
    libkf5notifications-dev \
    libkf5parts-dev \
    libx11-dev \
    libxcb1-dev \
    libxkbcommon-dev \
    libxext-dev \
    libxi-dev \
    libxtst-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    mesa-common-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    qtcreator \
    gdb \
    valgrind \
    gettext
# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."
    local BASE_DIR="${BUILD_DIR}/astra-qt-base"
    local TEMP_DIR="${BUILD_DIR}/runtime-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy runtime system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-qt-runtime.tar.gz" \
        --exclude='dev/*' --exclude='proc/*' --exclude='sys/*' --exclude='run/*' \
        --exclude='tmp/*' --owner=root --group=root .) || handle_error "Failed to create runtime archive"

    sudo rm -rf "${TEMP_DIR}"
}

create_sdk_archive() {
    log "Creating SDK archive..."
    local BASE_DIR="${BUILD_DIR}/astra-qt-sdk"
    local TEMP_DIR="${BUILD_DIR}/sdk-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy SDK system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-qt-sdk.tar.gz" \
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
    tar xzf "${BUILD_DIR}/astra-qt-runtime.tar.gz" -C "${RUNTIME_DIR}/usr/" || \
        handle_error "Failed to extract runtime archive"

    cat > "${RUNTIME_DIR}/metadata" << EOF
[Runtime]
name=${PLATFORM_ID}
arch=${ARCH}
branch=${VERSION}

[Environment]
PATH=/app/bin:/usr/bin:/bin
XDG_DATA_DIRS=/app/share:/usr/share:/usr/share/runtime/share:/run/host/share
QT_PLUGIN_PATH=/app/lib/qt5/plugins:/usr/lib/qt5/plugins
QT_QPA_PLATFORM=xcb
EOF
}

create_flatpak_sdk() {
    log "Creating Flatpak SDK structure..."

    rm -rf "${SDK_DIR}"/*
    mkdir -p "${SDK_DIR}/usr"
    mkdir -p "${SDK_DIR}/files/"{dev,proc,sys}

    # Распаковываем систему в usr
    tar xzf "${BUILD_DIR}/astra-qt-sdk.tar.gz" -C "${SDK_DIR}/usr/" || \
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
QT_PLUGIN_PATH=/app/lib/qt5/plugins:/usr/lib/qt5/plugins
QT_QPA_PLATFORM=xcb

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
        --subject="Astra Qt Runtime ${VERSION}" \
        --body="Based on Astra Linux" \
        "${RUNTIME_DIR}/usr" || handle_error "Failed to commit runtime to repository"

    # Коммит SDK в OSTree
    ostree --repo="${REPO_DIR}" commit \
        --branch="${SDK_ID}" \
        --subject="Astra Qt SDK ${VERSION}" \
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
   flatpak remote-add astra-qt-repo ${REPO_DIR}

2. Install runtime and SDK:
   flatpak install astra-qt-repo ${PLATFORM_ID}
   flatpak install astra-qt-repo ${SDK_ID}

The repository is located at: ${REPO_DIR}

EOF
}

main() {
    log "Starting Astra Qt Platform build..."

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