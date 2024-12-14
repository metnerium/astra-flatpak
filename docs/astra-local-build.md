# Сборка Astra Flatpak инфраструктуры

Инструкция описывает процесс локальной сборки всех компонентов Astra Flatpak инфраструктуры.

Все сборочные процессы уже собраны в bash скрипты 

Методология сборки описана схематично:
```mermaid
graph TD
    %% Стили для блоков
    classDef prepBlock fill:#d4edda,stroke:#333,stroke-width:2px,color:black
    classDef runtimeBlock fill:#cce5ff,stroke:#333,stroke-width:2px,color:black
    classDef sdkBlock fill:#fff3cd,stroke:#333,stroke-width:2px,color:black
    classDef repoBlock fill:#e2e3e5,stroke:#333,stroke-width:2px,color:black

    %% Подготовка
    Init[Подготовка структуры каталогов]:::prepBlock
    Init --> Runtime
    Init --> SDK

    %% Процесс сборки Runtime
    subgraph Runtime[Сборка Runtime]
        direction TB
        R1[Создание базовой системы через debootstrap]:::runtimeBlock
        R2[Установка компонентов]:::runtimeBlock
        R3[Создание архива Runtime]:::runtimeBlock
        R4[Формирование структуры Flatpak Runtime]:::runtimeBlock
        
        R1 --> R2
        R2 --> R3
        R3 --> R4
    end

    %% Процесс сборки SDK
    subgraph SDK[Сборка SDK]
        direction TB
        S1[Создание базовой системы через debootstrap]:::sdkBlock
        S2[Установка инструментов разработки]:::sdkBlock
        S3[Создание архива SDK]:::sdkBlock
        S4[Формирование структуры Flatpak SDK]:::sdkBlock
        
        S1 --> S2
        S2 --> S3
        S3 --> S4
    end

    %% Работа с репозиторием
    R4 --> Repo[Работа с репозиторием]
    S4 --> Repo
    
    subgraph Repo
        direction TB
        RI[Инициализация OSTree репозитория]:::repoBlock
        RC[Коммит компонентов]:::repoBlock
        RE[Экспорт в формат Flatpak]:::repoBlock
        RU[Обновление метаданных репозитория]:::repoBlock
        
        RI --> RC
        RC --> RE
        RE --> RU
    end

    %% Завершение
    RU --> Clean[Очистка временных файлов]:::prepBlock
    Clean --> Final[Готовый репозиторий с компонентами]:::prepBlock
```

## Предварительные требования

### Системные требования
- Astra Linux 
- Минимум 20GB свободного места
- Минимум 4GB RAM
- Права sudo

### Необходимые пакеты
```bash
sudo apt-get update
sudo apt-get install -y \
    flatpak \
    flatpak-builder \
    git \
    debootstrap \
    sudo \
    ostree
```

## Получение исходного кода

```bash
git clone https://git.devos.astralinux.ru/AstraOS/flatpak.git
cd flatpak
```

## Структура проекта
```
flatpak/
├── build_all.sh          # Основной скрипт сборки          
└── scripts/              # Скрипты сборки компонентов
    ├── build_main.sh
    ├── build_qt.sh
    ├── build_gtk.sh
```

## Процесс сборки

### Автоматическая сборка всех компонентов
```bash
sudo ./build_all.sh
```

### Порядок сборки компонентов
1. mainPlatform - базовый runtime
2. mainSdk - базовый SDK
3. Qt runtime
4. qtSdk
5. Gtk runtime
6. gtkSdk

### Ручная сборка отдельных компонентов
```bash
# Сборка mainPlatform
sudo ./scripts/build_main.sh

# Сборка Qt компонентов
sudo ./scripts/build_qt.sh

# Сборка GTK компонентов
sudo ./scripts/build_gtk.sh
```

## Проверка результатов сборки

После сборки в каталоге проекта появятся папки repo и build_dir 
### Проверка репозитория
```bash
flatpak remote-add --if-not-exists --no-gpg-verify local-astra repo
flatpak remote-ls local-astra
```

Ожидаемый вывод:
```
org.astra.mainPlatform
org.astra.mainSdk
org.astra.Qt
org.astra.qtSdk
org.astra.Gtk
org.astra.gtkSdk
```

### Тестовая установка компонентов
```bash
flatpak install local-astra org.astra.mainPlatform
flatpak install local-astra org.astra.Qt
```

## Возможные проблемы

### Ошибки debootstrap
При ошибках debootstrap проверьте:
- Доступность репозиториев Astra Linux
- Правильность настройки сети
- Наличие прав sudo

### Ошибки сборки flatpak
- Убедитесь в наличии всех зависимостей
- Проверьте корректность манифестов

## Очистка

### Очистка build директории
```bash
sudo rm -rf build_dir/*
```

