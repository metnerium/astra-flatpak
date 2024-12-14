# Локальная сборка сред выполнения Flathub 
В настоящее время доступны три основные среды выполнения: Freedesktop, GNOME и KDE, все из которых размещены на [Flathub](https://flathub.org/). Каждая среда выполнения поставляется с родительским SDK для сборки.
1. Среда [выполнения Freedesktop](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/) — это стандартная среда выполнения, которую можно использовать для любого приложения. Это содержит набор необходимых библиотек, обеспечивает графику и стек набора инструментов и формирует основу сред выполнения GNOME и KDE.

2. Среда [выполнения GNOME](https://gitlab.gnome.org/GNOME/gnome-build-meta) подходит для любого приложения, использующего платформу GNOME. Строится на основе среды выполнения Freedesktop и добавляет библиотеки и компоненты, используется платформой GNOME.

3. Среда [выполнения KDE](https://invent.kde.org/packaging/flatpak-kde-runtime) также основана на среде выполнения Freedesktop и включает в себя Qt и KDE Frameworks. Подходит для любого приложения, использующего KDE платформу и большинство приложений на базе Qt.

## Архитектура
```mermaid
graph TD
    classDef sourceBlock fill:#ff9999,stroke:#333,stroke-width:2px,color:black
    classDef sdkBlock fill:#99ff99,stroke:#333,stroke-width:2px,color:black
    classDef runtimeBlock fill:#9999ff,stroke:#333,stroke-width:2px,color:black
    classDef libBlock fill:#ffff99,stroke:#333,stroke-width:2px,color:black
    classDef flatpakBlock fill:#ff99ff,stroke:#333,stroke-width:2px,color:black

    Flathub[Репозиторий Flathub]:::sourceBlock

    subgraph FreedesktopLevel["Базовый уровень Freedesktop"]
        direction TB
        subgraph FreedesktopSDK["Freedesktop SDK"]
            direction LR
            FSDK[Базовый SDK]:::sdkBlock
            FTools[Инструменты сборки]:::libBlock
            FLib[Базовые библиотеки]:::libBlock
        end
        
        subgraph FreedesktopRuntime["Freedesktop Runtime"]
            direction LR
            FRT[Базовый Runtime]:::runtimeBlock
            CoreLibs[Основные библиотеки]:::libBlock
            Graphics[Графический стек]:::libBlock
        end
    end

    subgraph DesktopLevel["Окружения рабочего стола"]
        direction LR
        subgraph GNOME["GNOME Platform"]
            direction TB
            GSDK[GNOME SDK]:::sdkBlock
            GRT[GNOME Runtime]:::runtimeBlock
            GLibs[GNOME библиотеки]:::libBlock
            GTK[GTK+ окружение]:::libBlock
        end

        subgraph KDE["KDE Platform"]
            direction TB
            KSDK[KDE SDK]:::sdkBlock
            KRT[KDE Runtime]:::runtimeBlock
            KLibs[KDE Frameworks]:::libBlock
            QT[Qt окружение]:::libBlock
        end
    end

    FlatpakApps[Flatpak приложения]:::flatpakBlock

    Flathub --> FreedesktopSDK
    Flathub --> FreedesktopRuntime
    
    FreedesktopSDK --> GSDK
    FreedesktopSDK --> KSDK
    
    FreedesktopRuntime --> GRT
    FreedesktopRuntime --> KRT
    
    GSDK --> GLibs
    GSDK --> GTK
    
    KSDK --> KLibs
    KSDK --> QT
    
    GRT --> FlatpakApps
    KRT --> FlatpakApps
    FRT --> FlatpakApps

    linkStyle default stroke:#333,stroke-width:2px
```


### Клонируйте репозиторий
```bash
git clone https://git.devos.astralinux.ru/AstraOS/flatpak.git
```

### Установите необходимые инструменты
```bash
sudo apt install flatpak flatpak-builder ostree 
```
### Сборка Freedesktop 
```bash
mainline/fd_builder.sh
```
### Сборка Gnome
```bash
mainline/gnome_builder.sh
```
### Сборка Kde
```bash
mainline/kde_builder.sh
```