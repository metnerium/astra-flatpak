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

log_execution "build_gtk.sh"
scripts/build_gtk.sh
check_status "build_gtk.sh"

log_execution "build_qt.sh"
scripts/build_qt.sh
check_status "build_qt.sh"


echo "Все скрипты сборки успешно выполнены"
