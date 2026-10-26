# Актуальное состояние odins-docker

Обновлено: 2026-10-26 (Asia/Novosibirsk).

## Назначение

Самостоятельная и понятная сборка Docker-образов 1С вместо сложной цепочки
из форка https://github.com/LesTLi/onec-docker. Исходный проект:
https://github.com/firstBitMarksistskaya/onec-docker.
Ранее пользователь собирал образ скриптом `build_base_test-utils.sh`.

## Требования и решения из обсуждения

- Версия платформы: **8.3.27.2130**.
- Два конечных образа: **onec-test** и **server**.
- `onec-test` нужен для тестирования конфигурации в Jenkins Pipeline.
- `server` нужен для **ibcmd**: установка пакетов
  `1c-enterprise*-{common,server}*.deb`. Автозапуск кластера не требуется.
- Поддержать локальный дистрибутив и автоматическое скачивание с портала 1С.
  Согласован выбор `DIST_SOURCE=local|download`, по умолчанию `local`;
  учётные данные загрузки передаются через BuildKit secrets.
- Устранить необходимость root: инструменты доступны обычному пользователю,
  файлы workspace создаются с UID/GID Jenkins.
- В `/opt/1cv8/conf/conf.cfg` нужна строка
  `DisableUnsafeActionProtection=.*` и `SystemLanguage=RU`.
- В `/opt/1cv8/common/1cestart.cfg` нужна строка `UseHWLicenses=0`.
- Владелец попросил постоянно поддерживать актуальные записи по проекту.
- Сборку и интеграционные проверки выполнять в GitHub Actions на hosted
  Linux runner: локальный компьютер ограничен в доступе к зависимостям.
  Локальная сборка не является условием приёмки.
- Подтверждён план с INSTALL_FORMAT=deb|run. Способы не смешиваются
  внутри одной установки.

## Исследование

В форке OneScript установлен в `/root/.local/share/ovm`, этот каталог
добавлен в PATH. Это конкретный источник недоступности инструментов
непривилегированному пользователю. Не переносить такую установку.

Старая цепочка включает клиент 1С, Xvfb/VNC, OneScript с add и
vanessa-runner, Java 17, scrot/nircmd, pandoc и сетевые утилиты.
Точный состав нового образа и совместимость зависимостей проверяются
при реализации; наличие в старом образе не доказывает необходимость каждой
зависимости в новом.

## Текущий этап

Реализация и проверка завершены в ветке feat/images-actions.
Создан [черновик PR #1](https://github.com/LesTLi/odins-docker/pull/1).
Добавлены оба Dockerfile, общие скрипты, workflows Check и Build and test,
тесты, README и пример Jenkins. Итоговая матрица сборки, smoke и экспорта
прошла в Actions 40265588178 (код 417ed4a): восемь сборок и четыре TAR,
save/load и upload. Версионирование подтверждено владельцем и реализовано:
IMAGE_VERSION=1.0.0, независимая версия 1С, run ID/attempt, OCI labels,
TAR/SHA256/JSON в private Actions artifacts с retention 1 день.
PR подготовлен к рассмотрению;
merge и публикация образов в registry не выполнялись.

Выбраны Ubuntu 22.04, OneScript 1.9.4, OPM 1.7.1, Vanessa Runner 2.6.1,
ADD 6.9.5, Java 17. YARD 1.14.0 используется только для скачивания.
Точные источники и ограничения фиксации — [dependencies.md](dependencies.md).
Ход реализации и решения — [implementation-progress.md](implementation-progress.md).

## Ограничения и результаты проверок

- Проверено через GitHub: LesTLi/odins-docker — private, default branch main.
  Workflows созданы и запускаются на push рабочей ветки. Владелец подтвердил
  добавление Actions secrets ONEC_USERNAME и ONEC_PASSWORD 2026-10-23.
  Доступ к релизу подтверждён полной сборкой server/deb.

- Локальная сборка и тесты не запускаются: по требованию владельца
  вся проверка выполняется на GitHub-hosted runner.
- Пользователь предоставил путь к v8-install-deps.sh в локальном каталоге
  client_8_3_27_2130.deb64. Скрипт прочитан без запуска; выводы сохранены
  в installation-notes.md. Локальная клиентская поставка не содержит
  common/server; CI получает полную поставку с портала.
- Check прошёл в Actions 40265591768: Bash, ShellCheck, Hadolint,
  actionlint, выбор пакетов, конфигурация, версии/релизные gates,
  export guards и реальный release TAR с двумя тегами.
- tools/server и tools/onec-test успешно собраны и проверены в Actions
  40265588178: non-root UID/GID, workspace, stdin, exit code и SIGTERM;
  для onec-test также OneScript/OPM/Vanessa Runner/Java, Xvfb и снимок экрана.
  Это слои зависимостей, без 1С.
- Отсутствие lambdas в зависимостях YARD исправлено и проверено в
  Actions 39898890522. YARD 1.9.2 из устаревшего зеркала возвращал пустую
  поставку. Официальный YARD 1.14.0 с отдельным OneScript 2.2.0 успешно
  скачал платформу в Actions 39931621754.
- [Actions 40265588178](https://github.com/LesTLi/odins-docker/actions/runs/40265588178):
  server/onec-test × deb/run × download/local — все 8 сборок и full smoke GREEN.
  Проверены ibcmd, настройки, динамические библиотеки, non-root UID/GID,
  владелец workspace, stdin, exit code, SIGTERM; для onec-test также
  OneScript/OPM/Vanessa Runner/Java, Xvfb и снимок экрана.
  Четыре итоговых образа имеют уникальные теги, проверены save/load и
  загружены в Artifacts с SHA256/JSON. Известный риск SIGPIPE в проверке
  docker logs устранён чтением журнала из файла.
- Предыдущую нехватку места runner устранили удалением неиспользуемых SDK
  (свободно 35 GiB вместо 13 GiB) и перемещением временных дистрибутивов
  вместо повторного копирования.
- Настоящий RUN --help подтвердил имена компонентов и включённый по умолчанию
  client_full. Явно отключены лишние компоненты; отсутствие 1cv8/1cv8c
  в server подтверждено итоговыми smoke для обоих форматов и источников.
- Независимое ревью версионирования/экспорта и исправления smoke не выявило
  новых важных ошибок;
  прежние четыре замечания исправлены.
- Первоначальное ограничение записи .git устранено разрешённым запуском:
  коммиты создаются и отправляются в рабочую ветку.

## Следующие шаги

Схема и правила выпуска — [versioning.md](versioning.md).
RED нового helper подтверждён в Actions 40263251522, итоговый GREEN —
40265591768 и 40265588178. Готовые TAR можно скачивать уже из рабочего
запуска ветки, merge для скачивания существующего артефакта не нужен.

1. Рассмотрение PR и merge в main выполняются владельцем отдельно.
   После merge станет доступен ручной workflow_dispatch.
2. Тестирование конкретной конфигурации и публикация в приватный registry
   остаются отдельными этапами: в текущем CI нет конфигурации и лицензии 1С.

История существенных изменений: [CHANGELOG.md](CHANGELOG.md).
