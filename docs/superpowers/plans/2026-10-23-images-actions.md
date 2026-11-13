# Образы 1С и GitHub Actions — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Собирать и проверять onec-test и server для 1С 8.3.27.2130 в GitHub Actions.

**Architecture:** Два Dockerfile используют общие скрипты установки и запуска.
Источник local/download независим от формата deb/run. Установка выполняется
при сборке с root, готовые инструменты работают без root с UID/GID Jenkins.

**Tech Stack:** Docker BuildKit, Bash, GitHub Actions, Linux amd64, DEB/RUN,
OneScript, Java 17, Xvfb. Версии инструментов закрепляются после проверки
официальных релизов, до написания соответствующего Dockerfile.

**Spec:** `docs/superpowers/specs/2026-10-23-docker-images-design.md`.
Также прочитать `docs/installation-notes.md` и `docs/PROJECT.md`.

Это исходный согласованный план. Фактическое выполнение, уточнения
интерфейсов и результаты CI ведутся в docs/implementation-progress.md;
актуальный статус — docs/PROJECT.md. Проверка перед merge выполняется
через push рабочей ветки; ручной запуск станет доступен после merge в main.

## Global Constraints

- Платформа 8.3.27.2130; Linux amd64; образы onec-test и server.
- Все сборки и исполняемые тесты выполняются в GitHub Actions.
- DIST_SOURCE=local|download; INSTALL_FORMAT=deb|run, по умолчанию deb.
- Реализовать оба формата; это предложение плана, требующее его согласования.
- ONEC_USERNAME и ONEC_PASSWORD — только secrets, не ARG и не логи.
- В conf.cfg: DisableUnsafeActionProtection=.* и SystemLanguage=RU.
- В common/1cestart.cfg: UseHWLicenses=0.
- В onec-test: Java 17 и FtsJavaOpts=--add-opens java.base/java.lang=ALL-UNNAMED.
- Не смешивать RUN и DEB в одной установке; не запускать ragent автоматически.
- Не публиковать образы в registry в рамках этого этапа.

## Review Focus

- Неполная поставка: отсутствуют common/server или версия/архитектура не та.
- Ошибка скачивания возвращает HTML вместо архива или раскрывает credentials.
- Произвольный UID отсутствует в passwd, HOME недоступен либо workspace с пробелами.
- Xvfb не стартует или дочерний процесс не завершается после SIGTERM.
- CI выглядит успешным после пропуска сборки из-за отсутствующих secrets.

## 1. Проверки и воспроизводимые входные данные

**Files:** `.github/workflows/check.yml`, `.gitattributes`, `.gitignore`,
`.dockerignore`, `versions.env`, `docs/dependencies.md`, `tests/`.

- [ ] Проверить официальные релизы OneScript, OPM/Vanessa Runner/add,
  инструмент скачивания 1С и совместимость с зависимостями платформы.
  Сохранить версии, источники, контрольные суммы и выбранную ОС в
  versions.env и docs/dependencies.md. Не выдумывать SHA и версии.
- [ ] Создать check.yml для push/pull_request: Bash syntax, ShellCheck,
  Hadolint, actionlint и тесты скриптов. Закрепить actions по проверенным SHA.
- [ ] Настроить LF, исключение секретов и дистрибутивов из Git, минимальный
  build context с явно разрешённым distr/. Не исключить нужные локальные пакеты.
- [ ] Запустить проверки через Actions после публикации рабочей ветки;
  проверить, что ошибочный тест действительно делает job красным, затем исправить.

## 2. Получение и установка платформы

**Files:** `scripts/acquire.sh`, `scripts/install-platform.sh`,
`scripts/install-deps.sh`, `scripts/configure-platform.sh`,
`tests/test-install-inputs.sh`, `distr/.gitkeep`.

**Interfaces:** acquire.sh SOURCE FORMAT IMAGE VERSION INPUT_DIR OUTPUT_DIR;
install-platform.sh FORMAT IMAGE VERSION DIST_DIR;
install-deps.sh common|ui; configure-platform.sh IMAGE VERSION.
IMAGE принимает только server или onec-test. Ошибки возвращают ненулевой код.
Загрузчик читает /run/secrets/onec_username и /run/secrets/onec_password.

- [ ] Написать тесты входов: неизвестные параметры, нет файлов, неверная
  версия/архитектура, отсутствующий common/server, пробелы в пути,
  несколько подходящих RUN-файлов. Все ошибки должны обнаруживаться до установки.
- [ ] Реализовать local/download с одним нормализованным выходным каталогом,
  проверкой архива и без молчаливого перехода между источниками.
- [ ] Для DEB выбирать common/server и дополнительно client для onec-test
  по метаданным; ставить через apt-get, запрещая старт служб при сборке.
- [ ] Для RUN сверить --help настоящего установщика в Actions; выбирать
  компоненты для ibcmd или полного клиента явно и запускать unattended.
  Не полагаться на состав по умолчанию или успех v8-install-deps.sh.
- [ ] Установить явные common/ui зависимости и системные Core Fonts,
  затем проверить наличие бинарников. Избежать установки графического стека в server.
- [ ] Настроить три общих ключа и FtsJavaOpts для onec-test без дублей,
  сохранив прочие параметры. Проверить версионный путь общей конфигурации.
- [ ] Выполнить тесты в check.yml; записать результат, зафиксировать изменения.

## 3. Непривилегированный запуск и server

**Files:** `server/Dockerfile`, `scripts/entrypoint.sh`,
`scripts/build.sh`, `tests/smoke.sh`.

**Interfaces:** build.sh IMAGE; читает versions.env и переопределения
ONEC_VERSION, DIST_SOURCE, INSTALL_FORMAT, IMAGE_TAG, DIST_DIR.
entrypoint.sh COMMAND [ARGS...] сохраняет аргументы и код возврата.
smoke.sh IMAGE_TAG server|onec-test запускается на Docker-host runner.

- [ ] Добавить smoke-тесты: id -u != 0; произвольный UID:GID 23456:23457;
  getent passwd для UID; HOME доступен; ibcmd выполняет справочную команду;
  каждый конфигурационный ключ присутствует ровно один раз.
- [ ] Проверять владельца созданного в bind mount файла с хоста;
  использовать каталог с пробелом, заранее принадлежащий тестовому UID/GID.
  Проверить передачу аргументов и exit 42 без изменения кода возврата.
- [ ] Реализовать HOME во временном приватном каталоге при недоступном HOME,
  nss_wrapper для неизвестного UID; не изменять системный passwd и workspace.
- [ ] Создать server/Dockerfile с доступным ibcmd в PATH, non-root USER,
  init-процессом и общей конфигурацией. Установщик подключать через BuildKit
  mount/отдельную стадию, чтобы архивы не оставались в слоях итогового образа.
- [ ] Проверить DEB и RUN server в Actions, включая отсутствие автозапуска ragent.

## 4. Образ тестирования

**Files:** `onec-test/Dockerfile`, `scripts/install-tools.sh`,
`scripts/test-entrypoint.sh`, `scripts/nircmd`, `tests/smoke.sh`.

- [ ] Расширить тесты: запуск oscript, opm, vanessa-runner и Java 17
  от default/произвольного UID; доступ к пакетам вне /root.
- [ ] Установить закреплённые инструменты в системный каталог. Добавить
  Xvfb, xauth, scrot, pandoc, нужные сетевые утилиты и VNC.
- [ ] Реализовать виртуальный экран с ожиданием готовности и ошибкой при
  неудачном старте. VNC выключен по умолчанию; включается явно с файлом
  пароля, подключение документировано с bind порта на localhost хоста.
- [ ] Проверить снимок экрана, nircmd savescreenshot с путём с пробелами,
  SIGTERM и остановку дочерних процессов. Unsupported nircmd commands — ошибка.
- [ ] Проверить оба формата установки onec-test через Actions.

## 5. Полный workflow сборки и тестов

**Files:** `.github/workflows/build.yml`, `scripts/ci-build-test.sh`.

- [ ] Настроить workflow_dispatch и push main, ubuntu-24.04 runner,
  contents:read, timeout и concurrency, fail-fast:false.
- [ ] Создать матрицу server/onec-test × deb/run. Для каждого сочетания
  собрать download, выполнить smoke.sh, экспортировать скачанный дистрибутив
  в приватный временный каталог runner, собрать local и повторить smoke.sh.
- [ ] Проверять наличие secrets в начале job с понятной ошибкой, не skip.
  Никаких secrets в pull_request workflow, shell tracing, build args и outputs.
- [ ] Использовать load:true для тестов на runner, push:false; не выгружать
  установщики и образ в artifacts. Отчёт GITHUB_STEP_SUMMARY содержит
  версию, источник, формат, образ и результаты проверок.
- [ ] Проверить workflow через actionlint; опубликовать в рабочей ветке,
  создать PR и прикрепить его к чату. Для ручного запуска workflow должен
  существовать в default branch: не сливать PR молча, явно учесть этот шаг.
- [ ] После доступности workflow в main запустить Actions, прочитать логи,
  исправлять реальные ошибки и повторять затронутые jobs до успеха либо
  конкретного внешнего препятствия (например, отсутствующего доступа к 1С).

## 6. Документация и итоговая проверка

**Files:** `README.md`, `examples/Jenkinsfile`, `docs/PROJECT.md`,
`docs/CHANGELOG.md`, `docs/dependencies.md`.

- [ ] Документировать secrets, Run workflow, форматы дистрибутива,
  команды build/run, ibcmd, UID/GID Jenkins, VNC, системные настройки,
  CIFS-блокировки и диагностику зависимостей. Не обещать доступность образа
  в registry до отдельной настройки публикации.
- [ ] Добавить Jenkins-пример с UID/GID фактического агента и workspace,
  без -u root, privileged и рекурсивного изменения прав.
- [ ] Проверить итоговый diff относительно спецификации. Внести результаты
  каждого Actions run и нерешённые ограничения в записи проекта.
- [ ] В отчёте различить успешную сборку, smoke-тесты и полноценные тесты
  конфигурации, для которых нужны конфигурация и лицензирование.

## Предлагаемый способ выполнения

Выполнять задачи последовательно в этом чате: основная часть зависит от
общего установщика и CI. Перед реализацией пользователь проверяет этот план
и выбирает самостоятельное выполнение агентом либо работу с субагентами.
