#!/bin/bash

check_dependencies() {
    local deps=("git" "python3" "flatpak" "ostree" )

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

setup_venv() {
    local dir=$1
    python3 -m venv "$dir/venv" || handle_error "Не удалось создать виртуальное окружение"
    source "$dir/venv/bin/activate" || handle_error "Не удалось активировать виртуальное окружение"
    pip install --upgrade pip || handle_error "Не удалось обновить pip"
    pip install BuildStream || handle_error "Не удалось установить BuildStream"
    pip install \
        BuildStream \
        dulwich \
        grpcio \
        Click \
        Jinja2 \
        pluginbase \
        protobuf \
        psutil \
        pyroaring \
        "ruamel.yaml" \
        requests \
        packaging \
        tomlkit \
        ujson || handle_error "Не удалось установить необходимые пакеты Python"
}

build_gnome_runtime() {
    check_dependencies

    WORK_DIR="$(mktemp -d)"
    echo "Рабочая директория: $WORK_DIR"
    cd "$WORK_DIR" || handle_error "Не удалось перейти в рабочую директорию"

    echo "Начинаем сборку GNOME Runtime..."

    git clone https://gitlab.gnome.org/GNOME/gnome-build-meta.git || \
        handle_error "Не удалось клонировать репозиторий gnome-build-meta"
    cd gnome-build-meta || handle_error "Не удалось перейти в директорию gnome-build-meta"

    setup_venv "$(pwd)"

    echo "Начинаем сборку GNOME Runtime компонентов..."
    bst build flatpak-runtimes.bst || handle_error "Не удалось собрать GNOME Runtime"

    mkdir -p repo
    bst checkout flatpak-runtimes.bst repo || \
        handle_error "Не удалось выполнить checkout GNOME Runtime"

    echo "Добавление репозитория GNOME Runtime в Flatpak..."
    flatpak remote-add --user --no-gpg-verify gnome-repo "$(pwd)/repo" || \
        handle_error "Не удалось добавить репозиторий GNOME"

    echo "Установка GNOME Runtime..."
    flatpak install -y gnome-repo org.gnome.Platform || \
        handle_error "Не удалось установить GNOME Platform"
    flatpak install -y gnome-repo org.gnome.Sdk || \
        handle_error "Не удалось установить GNOME Sdk"

    echo "Сборка GNOME Runtime успешно завершена!"
}

build_gnome_runtime