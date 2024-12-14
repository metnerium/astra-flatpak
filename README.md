# Astra Linux Flatpak 

### Сборка осуществляется из пакетов ![Astra Linux](https://img.shields.io/badge/Astra%20Linux-1.8-blue)

Инфраструктура Flatpak для Astra Linux предоставляет среду выполнения и разработки для создания изолированных приложений. Система включает в себя специализированные окружения для Qt/KDE и GTK/GNOME приложений.

## Документация
- [Архитектура](docs/architecture.md)
- [Сборка Astra flatpak](docs/astra-local-build.md)
- [Руководство разработчика](docs/developer-guide.md)
- [Локальная сборка Freedesktop Kde Gnome](mainline/README.md)

## Быстрый старт

### Требования
- Flatpak 
- flatpak-builder
  
### Установка

1. Установка базовых компонентов:
```bash
sudo apt-get install flatpak flatpak-builder
```

2. Добавление репозитория:
```bash
flatpak remote-add --if-not-exists astra-flatpak https://astraflathub.devos.astralinux.ru/
```

3. Установка:
```bash
# Базовые компоненты
flatpak install astra-flatpak org.astra.mainPlatform//1.8
flatpak install astra-flatpak org.astra.mainSdk//1.8
```
```bash
# Для Qt разработки
flatpak install astra-flatpak org.astra.Qt//1.8
flatpak install astra-flatpak org.astra.qtSdk//1.8
```
```bash
# Для GTK разработки
flatpak install astra-flatpak org.astra.Gtk//1.8
flatpak install astra-flatpak org.astra.gtkSdk//1.8
```





