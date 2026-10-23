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
  SHA256 закреплён по файлу официального release, скачанному в Actions
  39896577878; это фиксация полученного файла, не подпись издателя.
- YARD 1.14.0: официальный release автора, SHA256 из GitHub asset digest:
  https://github.com/arkuznetsov/yard/releases/tag/v.1.14.0.
  Используется только в стадии скачивания. Зеркало oscript-library/yard
  устарело на 1.9.2 и не включает исправления парсинга портала и вложенных
  Linux-архивов (upstream issues #40, #46, #77).
  Fluent 0.6.1 переустанавливается с зависимостями: копия из OPM не содержит
  lambdas, что выявил запуск yard --help в Actions 39897790928.
- OPM обновляется до закреплённого 1.7.1: версия из DEB не понимает
  метод packagedef ВерсияСреды, используемый Vanessa Runner 2.6.1.
  Источник: https://github.com/oscript-library/opm/releases/tag/v1.7.1.
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
