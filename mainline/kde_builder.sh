#!/bin/bash

check_dependencies() {
    local deps=("git" "make" "flatpak" "ostree")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Ошибка: $dep не установлен"
            exit 1
        fi
    done
}

handle_error() {
    echo "Ошибка: $1"
    exit 1
}

build_kde_runtime() {
    check_dependencies

    WORK_DIR="$(mktemp -d)"
    echo "Рабочая директория: $WORK_DIR"
    cd "$WORK_DIR" || handle_error "Не удалось перейти в рабочую директорию"

    echo "Начинаем сборку KDE Runtime..."

    git clone https://invent.kde.org/packaging/flatpak-kde-runtime.git || \
        handle_error "Не удалось клонировать репозиторий flatpak-kde-runtime"
    cd flatpak-kde-runtime || handle_error "Не удалось перейти в директорию flatpak-kde-runtime"


    echo "Настройка репозиториев KDE..."
    make remotes || handle_error "Не удалось настроить репозитории KDE"

    echo "Сборка базовых компонентов KDE Runtime..."
    make || handle_error "Не удалось выполнить базовую сборку KDE Runtime"

    echo "Сборка KDE SDK..."
    make org.kde.Sdk.app || handle_error "Не удалось собрать KDE Sdk"

    echo "Добавление репозитория KDE Runtime в Flatpak..."
    flatpak remote-add --user --no-gpg-verify kde-repo "$(pwd)/repo" || \
        handle_error "Не удалось добавить репозиторий KDE"

    echo "Установка KDE Runtime компонентов..."
    flatpak install -y kde-repo org.kde.Platform || \
        handle_error "Не удалось установить KDE Platform"
    flatpak install -y kde-repo org.kde.Sdk || \
        handle_error "Не удалось установить KDE Sdk"

    echo "Сборка KDE Runtime успешно завершена!"
}

build_kde_runtime