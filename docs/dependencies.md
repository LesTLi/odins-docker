# Зависимости и выбранные версии

- Базовая ОС: Ubuntu 22.04, единый набор репозиториев. Выбрана для
  доступности libwebkit2gtk-4.0-37 и Mono, требуемых текущим стеком.
  Это технический выбор для проверки в CI, не заявление о сертификации ОС.
- OneScript 1.9.4: официальный DEB, SHA256 в versions.env взят из
  GitHub release asset digest:
  https://github.com/EvilBeaver/OneScript/releases/tag/v1.9.4.
- Vanessa Runner 2.6.1: совместим с OneScript >=1.9.2, сохраняет CLI 2.x.
  Версия 3.x несовместима с прежними командами и требует OneScript 2.x:
  https://github.com/vanessa-opensource/vanessa-runner/releases/tag/v3.0.0.
- ADD 6.9.5: https://github.com/vanessa-opensource/add/releases/tag/v6.9.5.
- YARD 1.9.2: версия packagedef oscript-library/yard; используется только
  в стадии скачивания. Интерфейс releases get проверен по README проекта.
- OPM поставляется в DEB OneScript, не обновляется через update --all.
  Верхнеуровневые OPM-пакеты закреплены; транзитивные зависимости хаба могут
  меняться. Пока нет полного lock транзитивных пакетов, битовую
  воспроизводимость сборки не заявляем.
- Java 17 JRE: Ubuntu package openjdk-17-jre-headless.
- Общие/UI библиотеки взяты из предоставленного v8-install-deps.sh;
  подробный анализ — installation-notes.md. Устанавливаются явно с
  проверкой ошибок, без смешивания выпусков Linux.

Пакеты ОС получают обновления безопасности выбранного выпуска; базовый
образ закреплён выпуском, не digest. Дальнейшая фиксация digest должна
сопровождаться регулярным обновлением, а не бессрочным замораживанием ОС.
