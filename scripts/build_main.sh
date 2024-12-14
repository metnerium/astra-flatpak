#!/bin/bash

# Определение директорий
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_dir"
MANIFEST_DIR="${SCRIPT_DIR}/manifests"
REPO_DIR="${SCRIPT_DIR}/repo"
RUNTIME_DIR="${BUILD_DIR}/runtime"
SDK_DIR="${BUILD_DIR}/sdk"
PLATFORM_ID="org.astra.mainPlatform"
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
    local BASE_DIR="${BUILD_DIR}/astra-base"

    # Проверяем наличие базовой системы
    if [ -d "${BASE_DIR}" ] && [ -d "${BASE_DIR}/usr" ] && [ -d "${BASE_DIR}/etc" ]; then
        log "Base runtime system already exists, skipping debootstrap..."
        return 0
    fi

    # Очищаем если существует но неполная
    [ -d "${BASE_DIR}" ] && sudo rm -rf "${BASE_DIR}"
    mkdir -p "${BASE_DIR}"

    sudo debootstrap --arch=amd64 --variant=minbase \
        --include="apt-utils,locales,ca-certificates,dbus,systemd,bash,coreutils,util-linux,findutils,grep,gawk,sed" \
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

# Базовые пакеты
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata openssl ca-certificates

# Основные пакеты
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    zlib1g bzip2 xz-utils lz4 p7zip-full \
    openprinting-ppds libgutenprint9 aspell-en hunspell-ru unrar apt \
    atftp vim anacron quota mc less gostsum manpages-ru acpid apt-utils libijs-0.35 \
    wpasupplicant mueller7-dict ntfs-3g apt-transport-https openssh-client \
    acpi rsh-client expect powertop \
    systemd-timesyncd gutenprint-locales pcmciautils unzip \
    bind9-host ncurses-term dosfstools bash-completion \
    fakeroot lsof

# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

# Создаем базовую SDK систему
create_base_sdk() {
    log "Creating base SDK system..."
    local BASE_DIR="${BUILD_DIR}/astra-baseSdk"

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

# Устанавливаем инструменты разработки
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    make cmake gcc g++ build-essential dpkg-dev \
    autoconf automake libtool pkg-config gettext \
    intltool git patch python3-pip  \
    python3-venv python3-dev

# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
}

create_runtime_archive() {
    log "Creating runtime archive..."
    local BASE_DIR="${BUILD_DIR}/astra-base"
    local TEMP_DIR="${BUILD_DIR}/runtime-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy runtime system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-runtime.tar.gz" \
        --exclude='dev/*' --exclude='proc/*' --exclude='sys/*' --exclude='run/*' \
        --exclude='tmp/*' --owner=root --group=root .) || handle_error "Failed to create runtime archive"

    sudo rm -rf "${TEMP_DIR}"
}

create_sdk_archive() {
    log "Creating SDK archive..."
    local BASE_DIR="${BUILD_DIR}/astra-baseSdk"
    local TEMP_DIR="${BUILD_DIR}/sdk-temp"

    [ -d "${TEMP_DIR}" ] && sudo rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Копируем полную систему
    sudo cp -a "${BASE_DIR}/." "${TEMP_DIR}/" || handle_error "Failed to copy SDK system"

    # Архивируем с исключениями
    (cd "${TEMP_DIR}" && sudo tar czf "${BUILD_DIR}/astra-sdk.tar.gz" \
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
    tar xzf "${BUILD_DIR}/astra-runtime.tar.gz" -C "${RUNTIME_DIR}/usr/" || \
        handle_error "Failed to extract runtime archive"

    cat > "${RUNTIME_DIR}/metadata" << EOF
[Runtime]
name=${PLATFORM_ID}
arch=${ARCH}
branch=${VERSION}

[Environment]
PATH=/app/bin:/usr/bin:/bin
XDG_DATA_DIRS=/app/share:/usr/share
EOF
}

create_flatpak_sdk() {
    log "Creating Flatpak SDK structure..."

    rm -rf "${SDK_DIR}"/*
    mkdir -p "${SDK_DIR}/usr"
    mkdir -p "${SDK_DIR}/files/"{dev,proc,sys}

    # Распаковываем систему в usr
    tar xzf "${BUILD_DIR}/astra-sdk.tar.gz" -C "${SDK_DIR}/usr/" || \
        handle_error "Failed to extract SDK archive"

    cat > "${SDK_DIR}/metadata" << EOF
[Runtime]
name=org.astra.mainSdk
arch=${ARCH}
branch=${VERSION}
runtime=${PLATFORM_ID}/${ARCH}/${VERSION}

[Environment]
PATH=/app/bin:/usr/bin:/bin
XDG_DATA_DIRS=/app/share:/usr/share

[Extension org.astra.mainSdk]
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
        --subject="Astra Platform Runtime ${VERSION}" \
        --body="Based on Astra Linux" \
        "${RUNTIME_DIR}/usr" || handle_error "Failed to commit runtime to repository"

    # Коммит SDK в OSTree
    ostree --repo="${REPO_DIR}" commit \
        --branch="org.astra.mainSdk" \
        --subject="Astra Platform SDK ${VERSION}" \
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
   flatpak remote-add astra-repo repo

2. Install runtime and SDK:
   flatpak install astra-repo ${PLATFORM_ID}
   flatpak install astra-repo org.astra.mainSdk

The repository is located at: ${REPO_DIR}

EOF
}

main() {
    log "Starting Astra Platform build..."

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
