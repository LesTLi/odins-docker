# Зависимости и выбранные версии

- Базовая ОС: Ubuntu 22.04, единый набор репозиториев. Выбрана для
  доступности libwebkit2gtk-4.0-37 и библиотек текущего стека.
  Это технический выбор для проверки в CI, не заявление о сертификации ОС.
- OneScript 2.2.0: официальный standalone Linux x64 ZIP для onec-test
  и отдельной стадии downloader:
  https://github.com/EvilBeaver/OneScript/releases/tag/v2.2.0.
  SHA256 точного OneScript-2.2.0-linux-x64.zip взят из GitHub release asset
  digest. DEB для 2.2.0 в release отсутствует. Mono больше не требуется.
  ONESCRIPT_VERSION/SHA256 задают runtime onec-test, DOWNLOADER_ONESCRIPT_*
  независимо задают загрузчик. В конечном onec-server OneScript отсутствует.
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
- OPM обновляется до закреплённого 1.7.1. Исторически обновление было нужно:
  OPM из DEB OneScript 1.9.4 не понимал метод packagedef ВерсияСреды,
  используемый Vanessa Runner 2.6.1. Запуск OPM/Vanessa Runner с OneScript
  2.2.0 от двух UID/GID проверен в Actions 40657846880; проверка
  пользовательской конфигурации с лицензией выполняется отдельно.
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

## Fluent и обновление контрольных сумм

Fluent — библиотека обработки коллекций для OneScript:
https://github.com/oscript-library/fluent. Явная установка FLUENT_VERSION
нужна downloader, чтобы YARD получил все зависимости, включая lambdas.
Это внутренняя библиотека инструментов, а не отдельная команда для Jenkins.

При обновлении скачиваемого файла обновлять парой VERSION и SHA256:

| Параметр SHA256 | Точный файл текущей версии |
| --- | --- |
| ONESCRIPT_SHA256 | OneScript-2.2.0-linux-x64.zip |
| DOWNLOADER_ONESCRIPT_SHA256 | OneScript-2.2.0-linux-x64.zip |
| YARD_SHA256 | yard-1.14.0.ospx |
| ADD_SHA256 | add-6.9.5.ospx |

Брать digest точного файла из GitHub release assets API, без префикса
sha256:. Если digest отсутствует (как у ADD 6.9.5), скачать официальный
файл и вычислить sha256sum в Actions либо Get-FileHash -Algorithm SHA256
для уже скачанного файла в Windows. Самостоятельный расчёт закрепляет
полученные байты, но не является независимой проверкой подлинности.
Несовпадение суммы останавливает сборку до установки файла.

Изменение только IMAGE_VERSION или ONEC_VERSION не требует изменения
этих сумм. Для OPM_VERSION/FLUENT_VERSION/VRUNNER_VERSION отдельных сумм
пока нет: установка выполняется через OPM с указанной версией пакета.
SHA256 готового TAR генерируется автоматически и не берётся из versions.env.
