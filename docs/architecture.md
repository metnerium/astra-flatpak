# Архитектура Astra Flatpak

```mermaid
---
config:
  look: classic
---
flowchart TD
 subgraph bg4["Repositories"]
        A1["Main Repo"]
        A2["Extended Repo"]
  end
 subgraph bg1["Main Runtime/Sdk"]
        B2["astra.mainPlatform"]
        C2["astra.mainSdk"]
  end
 subgraph bg2a["Qt/KDE Environment"]
        F2["astra.Qt"]
        G2["astra.qtSdk"]
  end
 subgraph bg2b["GTK/GNOME Environment"]
        J2["astra.Gtk"]
        K2["astra.gtkSdk"]
  end
 subgraph bg2["Addition Runtime/Sdk"]
        bg2a
        bg2b
  end
 subgraph bg3a["Production"]
        D4["Qt/KDE приложения"]
        E4["GTK/GNOME приложения"]
  end
 subgraph bg3b["Development"]
        D5["Qt/KDE разработка"]
        E5["GTK/GNOME разработка"]
  end
 subgraph bg3["Applications"]
        bg3a
        bg3b
  end
 subgraph bg5["Astra Flatpak architecture"]
        bg4
        bg1
        bg2
        bg3
  end
    B2 --> F2 & J2
    C2 --> G2 & K2
    F2 --> D4
    J2 --> E4
    G2 --> D5
    K2 --> E5
    A1 --> B2 & J2 & F2
    A2 --> C2 & G2 & K2
    style B2 fill:#dfd,stroke:#333,color:#333,fontcolor:#333
    style C2 fill:#dfd,stroke:#333,color:#333,fontcolor:#333
    style F2 fill:#f9e,stroke:#333,color:#333,fontcolor:#333
    style G2 fill:#f9e,stroke:#333,color:#333,fontcolor:#333
    style J2 fill:#bbf,stroke:#333,color:#333,fontcolor:#333
    style K2 fill:#bbf,stroke:#333,color:#333,fontcolor:#333
    style D4 fill:#ffd,stroke:#333,color:#333,fontcolor:#333
    style E4 fill:#ffd,stroke:#333,color:#333,fontcolor:#333
    style D5 fill:#eff,stroke:#333,color:#333,fontcolor:#333
    style E5 fill:#eff,stroke:#333,color:#333,fontcolor:#333
    style bg1 fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg2 fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg2a fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg2b fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg3 fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg3a fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg3b fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg4 fill:#ffffff,stroke:#333,color:#333,fontcolor:#333
    style bg5 fill:#ffffff,stroke:#333,color:#333,fontcolor:#333

```

## Базовые компоненты

### Main Runtime/SDK

#### astra.mainPlatform
Базовый runtime, содержащий основные компоненты системы:
- Системные библиотеки и утилиты
- Базовые компоненты безопасности
- Компоненты Parsec
- Основные системные утилиты

#### astra.mainSdk
Базовый SDK для разработки:
- Компиляторы (gcc, g++)
- Инструменты сборки (make, cmake)
- Базовые утилиты разработки
- Заголовочные файлы системных библиотек
- Инструменты отладки

## Дополнительные окружения

### Qt/KDE Environment

#### astra.Qt
Runtime для Qt приложений:
- Qt5 библиотеки
- KDE Frameworks
- Qt плагины
- Системы тем KDE
- Мультимедиа компоненты
- Зависимости Qt приложений

#### astra.qtSdk
SDK для разработки Qt приложений:
- Qt заголовочные файлы
- Qt инструменты разработки
- KDE инструменты разработки
- CMake модули для Qt
- Отладочные инструменты Qt

### GTK/GNOME Environment

#### astra.Gtk
Runtime для GTK приложений:
- GTK библиотеки
- GLib/GObject
- GNOME компоненты
- Системы тем GTK
- Мультимедиа компоненты GTK
- Зависимости GTK приложений

#### astra.gtkSdk
SDK для разработки GTK приложений:
- GTK заголовочные файлы
- GObject инструменты
- GNOME инструменты разработки
- Инструменты сборки GTK
- Отладочные инструменты GTK

