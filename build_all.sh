#!/bin/bash

check_status() {
    if [ $? -ne 0 ]; then
        echo "Ошибка при выполнении $1"
        exit 1
    fi
}

log_execution() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Запуск $1"
}

chmod +x scripts/build_*.sh

log_execution "build_main.sh"
scripts/build_main.sh
check_status "build_main.sh"

log_execution "build_mainSdk.sh"
scripts/build_mainSdk.sh
check_status "build_mainSdk.sh"

echo "Добавление локального репозитория..."
flatpak remote-add --if-not-exists local-repo repo --no-gpg-verify
check_status "добавление репозитория"

echo "Установка Platform и Sdk из локального репозитория..."
flatpak install local-repo org.astra.mainPlatform -y
check_status "установка Platform"
flatpak install local-repo org.astra.mainSdk -y
check_status "установка Sdk"

log_execution "build_gtk.sh"
scripts/build_gtk.sh
check_status "build_gtk.sh"

log_execution "build_gtkSdk.sh"
scripts/build_gtkSdk.sh
check_status "build_gtkSdk.sh"

log_execution "build_qt.sh"
scripts/build_qt.sh
check_status "build_qt.sh"

log_execution "build_qtsdk.sh"
scripts/build_qtsdk.sh
check_status "build_qtsdk.sh"

echo "Все скрипты сборки успешно выполнены"
