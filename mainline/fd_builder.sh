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

main() {
    check_dependencies

    WORK_DIR="$(mktemp -d)"
    echo "Рабочая директория: $WORK_DIR"
    cd "$WORK_DIR" || handle_error "Не удалось перейти в рабочую директорию"

    echo "Клонирование репозитория Freedesktop SDK..."
    git clone https://gitlab.com/freedesktop-sdk/freedesktop-sdk.git || \
        handle_error "Не удалось клонировать репозиторий freedesktop-sdk"
    cd freedesktop-sdk || handle_error "Не удалось перейти в директорию freedesktop-sdk"

    echo "Настройка виртуального окружения и установка зависимостей..."
    setup_venv "$(pwd)"


    echo "Начало сборки SDK и Platform..."
    bst build sdk.bst platform.bst || handle_error "Не удалось собрать sdk.bst и platform.bst"

    echo "Инициализация OSTree репозитория..."
    mkdir -p repo
    ostree init --mode=archive-z2 --repo=repo || handle_error "Не удалось инициализировать ostree репозиторий"

    for component in "sdk" "platform"; do
        echo "Экспорт и коммит компонента $component..."
        bst artifact checkout "$component.bst" --directory "$component-checkout/" || \
            handle_error "Не удалось выполнить checkout для $component"

        ostree commit --repo=repo \
            --branch=org.freedesktop.$([[ "$component" == "sdk" ]] && echo "Sdk" || echo "Platform")/x86_64/custom \
            "$component-checkout/" || handle_error "Не удалось выполнить commit для $component"
    done

    echo "Добавление репозитория в Flatpak..."
    flatpak remote-add --user --no-gpg-verify testrepo "$(pwd)/repo" || \
        handle_error "Не удалось добавить репозиторий"

    echo "Установка Platform и SDK..."
    flatpak install -y testrepo org.freedesktop.Platform//23.08 || \
        handle_error "Не удалось установить Platform"
    flatpak install -y testrepo org.freedesktop.Sdk//23.08 || \
        handle_error "Не удалось установить Sdk"

    echo "Сборка успешно завершена!"
}

main "$@"