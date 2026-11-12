# odins-docker

Два самостоятельных образа Linux amd64 для платформы **8.3.27.2130**:

| Образ | Назначение |
| --- | --- |
| `onec-server` | `ibcmd`, компоненты common/server, без автозапуска кластера |
| `onec-test` | Полный клиент, конфигуратор, OneScript, Vanessa Runner 2.6.1, ADD, Java 17, Xvfb и VNC |

Для onec-server каталог Dockerfile и аргумент scripts/build.sh по-прежнему
называются server; имя готового Docker-образа — onec-server.

Сборка и smoke-тесты всех сочетаний образа, формата и источника проверены
в GitHub Actions. Ссылки на запуски и границы проверок — в
[состоянии проекта](docs/PROJECT.md).

## GitHub Actions

Сборка и тестирование выполняются на GitHub-hosted Ubuntu runner.
Локальный Docker для разработки проекта не требуется.

1. В Settings → Secrets and variables → Actions добавьте secrets
   `ONEC_USERNAME` и `ONEC_PASSWORD` учётной записи с доступом к релизу 1С.
2. Workflow **Check** проверяет Bash, входные дистрибутивы, Dockerfile и YAML.
3. **Build and test** сначала собирает зависимости без платформы и проверяет
   non-root запуск. Формат для обоих образов читается из INSTALL_FORMAT
   в versions.env. Везде проверяются download и local.
4. Сборка запускается при push в рабочую ветку feat/images-actions
   и Git-теги вида v1.0.
   После появления workflow в main доступен Actions → Build and test →
   Run workflow с необязательным переопределением версии платформы.
   При push в main работает только Check, без сборки образов с 1С.

Отсутствующие secrets приводят к ошибке, а не к успешному пропуску сборки.
После проверок каждое задание сохраняет один итоговый образ в **Artifacts**:
TAR, контрольную сумму SHA256 и metadata JSON. Хранение — **1 день**.
Архив перед загрузкой проверяется через docker load с сопоставлением image ID
и labels. Registry в этом workflow не используется.

Если upload завершается с Artifact storage quota has been hit, освободите
хранилище или проверьте лимит Actions в GitHub Billing. Удаление artifacts
может не сразу снять блокировку: по документации upload-artifact storage
пересчитывается раз в 6–12 часов. После обновления квоты используйте Re-run
failed jobs; сборка намеренно не считается успешной без загрузки TAR.

## Скачать образ и загрузить на сервер

1. Откройте успешный запуск **Build and test** → **Artifacts**.
2. Выберите onec-test или onec-server; скачайте ZIP и распакуйте. Для
   разработческой и итоговой сборки формат указан в metadata JSON.
3. В каталоге распакованного артефакта проверьте SHA256 и загрузите TAR.
   Пример имени (номер запуска будет вашим):

```bash
sha256sum --check onec-test_1.0-1c8.3.27.2130-b123456.tar.sha256
docker load --input onec-test_1.0-1c8.3.27.2130-b123456.tar
```

Точный тег указан в Actions Summary, metadata JSON и выводе docker load.
На Windows SHA256 можно получить командой PowerShell `Get-FileHash -Algorithm SHA256`.
После загрузки используйте этот тег в Jenkins TEST_IMAGE; registry для этого
не требуется, если образ загружен в Docker daemon самого агента.

## Версии и выпуск

`IMAGE_VERSION=1.0` в versions.env — версия проекта, независимая от
`ONEC_VERSION=8.3.27.2130`. Уникальный тег сборки:
`onec-test:1.0-1c8.3.27.2130-b123456`.
`b` — run ID. Повторная попытка имеет тот же тег и заменяет artifact этого
запуска; attempt, image ID и SHA256 сохраняются в metadata JSON.

Версия 1С по умолчанию во всех запусках скрипта сборки берётся из
`ONEC_VERSION` в versions.env. Необязательное поле version ручного запуска
Actions переопределяет её только для этого запуска; пустое поле сохраняет
значение файла. Изменение versions.env действует и на автоматические сборки.

Для выпуска измените IMAGE_VERSION, внесите изменения в main и создайте
соответствующий Git-тег vX.Y (например v1.0). Несовпадение Git-тега и
IMAGE_VERSION — ошибка. Все запуски используют INSTALL_FORMAT из versions.env
(сейчас deb); к проверенному
образу добавляется итоговый тег onec-test:1.0-1c8.3.27.2130 или
onec-server:1.0-1c8.3.27.2130. Ручной запуск на Git-теге также выпускает
итоговый образ; на ветке — разработческий. Выбор формата — через versions.env
соответствующей ветки или тега, отдельного input install_format нет.
Итоговый тег сохраняется в том же TAR без пересборки; имя релизного TAR
не содержит формат/номер запуска. Версия проекта — два числа: 1.0, 1.1, 2.0.
Выпущенные Git-теги не переносите;
новая версия выпуска требует нового номера. Подробнее: [versioning.md](docs/versioning.md).

В артефакте также есть size-report.txt: фактический размер Docker image,
каталоги и крупнейшие файлы платформы, список DEB-пакетов с размерами.
Этот отчёт позволяет сравнить результат установки DEB и RUN.

## Источник и формат дистрибутива

`DIST_SOURCE=local|download` выбирает источник; `INSTALL_FORMAT=deb|run`
выбирает способ установки. По умолчанию используются local и deb.
В Actions установите INSTALL_FORMAT в versions.env: это единый выбор
для разработки и выпуска, для onec-test и onec-server. Прямой вызов
scripts/build.sh допускает явное переопределение через окружение.
Способы не смешиваются внутри образа.

В `distr/` положите распакованные файлы или архивы `.tar.gz`, `.tgz`,
`.tar.xz`, `.zip`. Подкаталоги разрешены.

- DEB/server: common и server одной версии, архитектура amd64.
- DEB/onec-test: common, server и client. Только клиентского архива
  недостаточно: common/server находятся в серверной поставке.
- RUN: ровно один `setup-full-8.3.27.2130-x86_64.run`.

Отдельный thin-client не устанавливается вместе с common. Для русского
интерфейса -nls не нужен. Версия и архитектура DEB проверяются по метаданным.
Для другой версии измените ONEC_VERSION и предоставьте соответствующие файлы;
совместимость другой версии не считается проверенной автоматически.

На Linux-машине с Docker Buildx и доступом к зависимостям:

```bash
INSTALL_FORMAT=deb bash scripts/build.sh server
INSTALL_FORMAT=run bash scripts/build.sh onec-test

# ONEC_USERNAME и ONEC_PASSWORD уже заданы в окружении средствами CI.
DIST_SOURCE=download INSTALL_FORMAT=run bash scripts/build.sh onec-test
```

Секреты передаются BuildKit через secret mounts, не через build args.
Загрузчик YARD изолирован в стадии сборки; его вывод с потенциальными
данными авторизации не попадает в логи. При ошибке проверяйте доступ к
версии на портале; не включайте shell tracing для диагностики пароля.

## Запуск без root и Jenkins

```bash
# Используйте свои теги из metadata JSON; здесь приведены примеры.
SERVER_IMAGE=onec-server:1.0-1c8.3.27.2130-b123456
TEST_IMAGE=onec-test:1.0-1c8.3.27.2130-b123456
docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$PWD,dst=/workspace" \
  "$SERVER_IMAGE" ibcmd --help

docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$PWD,dst=/workspace" \
  "$TEST_IMAGE" vrunner --help
```

По умолчанию пользователь — `usr1cv8`, группа — `grp1cv8`,
UID/GID — 10001:10001, HOME — `/home/usr1cv8`. Для Jenkins передавайте UID/GID
пользователя агента, которому принадлежит workspace. Произвольный UID
поддерживается через nss_wrapper; при недоступном HOME создаётся приватный
временный каталог. Для сохранения пользовательских данных смонтируйте
доступный этому UID домашний каталог и задайте HOME.

Контейнер не меняет владельца смонтированного workspace. 1С создаёт файлы
с правами 0660: для нескольких UID используйте общую группу и setgid
каталога базы на хосте. CIFS монтируйте на хосте без nobrl, а в Samba
не используйте locking=no.

### Примеры Jenkinsfile

В обоих примерах укажите метку своего Docker-агента вместо `docker-linux`
и задайте `TEST_IMAGE` тегом образа, загруженного в Docker агента.

- [`agent { docker }`](examples/JenkinsfileDockerAgent) — Jenkins создаёт контейнер
  на весь Pipeline. Используются `ONEC_JENKINS_AGENT=1` и одна проверка
  `onec-wait-ready` перед первой командой 1С.
- [`docker run` в шаге `sh`](examples/JenkinsfileDockerRun) — Jenkins
  выделяет обычный агент с Docker. Команда монтирует workspace, запускает
  контейнер с UID/GID агента и передаёт скрипт в штатный entrypoint.
  Используется режим `0` по умолчанию. Entrypoint сам ждёт готовности Xvfb.

### Цепочки запуска `onec-test`

В обоих режимах `tini` запускает `onec-entrypoint` и передаёт сигналы
его группе процессов. `onec-entrypoint` подключает `test-entrypoint`.
Адрес дисплея по умолчанию — `:99`.

**`ONEC_JENKINS_AGENT=0` (по умолчанию).** Отсутствующее или пустое
значение трактуется как `0`. Это режим обычного `docker run`.

1. Entrypoint подготавливает доступный для записи `HOME`, при необходимости
   создаёт записи пользователя и группы через `nss_wrapper` и применяет
   `ONEC_USE_HW_LICENSES` в пользовательской конфигурации 1С.
2. `test-entrypoint` запускает Xvfb и ждёт, пока `xdpyinfo` подключится
   к дисплею. При `ENABLE_VNC=1` он также запускает `x11vnc`.
3. Entrypoint запускает переданную Docker команду с подготовленным
   окружением. Отдельная проверка `onec-wait-ready` в этом режиме не нужна.
   Когда команда завершается, entrypoint останавливает фоновые процессы.

**`ONEC_JENKINS_AGENT=1`** предназначен для `agent { docker }`.
Сохраните штатный entrypoint и передайте Docker-аргументы из
[примера Jenkinsfile](examples/JenkinsfileDockerAgent).

1. Jenkins создаёт контейнер и передаёт служебную команду `cat`.
   Entrypoint удаляет старый маркер готовности и сразу запускает `cat`.
   Jenkins может начать выполнять шаги, пока окружение 1С готовится.
2. Entrypoint создаёт общий `HOME`, готовит записи UID/GID для
   `nss_wrapper` и записывает `UseHWLicenses`. Передайте
   `ONEC_USE_HW_LICENSES` через Docker `args`, чтобы значение было доступно
   при старте. `NSS_WRAPPER_PASSWD` и `NSS_WRAPPER_GROUP` задают пути к
   файлам пользователей и групп, а `LD_PRELOAD` подключает библиотеку,
   которая читает их в шагах Jenkins.
3. `test-entrypoint` запускает один Xvfb, ждёт подключения `xdpyinfo`,
   при включённом VNC запускает `x11vnc` и создаёт `$HOME/.onec-ready`.
4. Перед первой командой 1С выполните `sh 'onec-wait-ready'` **один раз
   на контейнер**. Команда ждёт маркер и проверяет подключение к Xvfb из
   шага Jenkins. Если окружение уже готово, она возвращается сразу.
   При отсутствии готовности шаг завершается с ошибкой примерно через
   20 секунд.
5. Дальше вызывайте `vrunner` напрямую. Шаги `sh` используют общий
   дисплей и `HOME` через `docker exec`. При остановке контейнера
   entrypoint завершает фоновые процессы.

## Графические тесты

В UI-зависимости включён `at-spi2-core`, предоставляющий сервис
`org.a11y.Bus`. Он устраняет предупреждение GTK/AT-SPI при создании базы
через `vrunner init-dev`, сохраняя поддержку accessibility.

onec-test запускает Xvfb автоматически; DISPLAY по умолчанию :99,
XVFB_SCREEN — 1440x900x24. Для снимка экрана:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$PWD:/workspace" "$TEST_IMAGE" \
  nircmd savescreenshot '/workspace/screen shot.png'
```

### Включение VNC

По умолчанию VNC выключен. При `ENABLE_VNC=1` в обоих режимах
`x11vnc` показывает дисплей 1С и принимает подключения без пароля.

1. Добавьте эти параметры перед именем образа в `docker run` или в
   строку Docker `args` в Jenkinsfile. Публикуйте порт VNC только на
   localhost Docker-хоста.

   ```text
   -e ENABLE_VNC=1
   -p 127.0.0.1:5907:5900
   ```

2. Пока контейнер работает, с рабочей станции откройте SSH-туннель до
   Docker-хоста и подключите VNC-клиент к `127.0.0.1:5907`.

   ```bash
   ssh -N -L 5907:127.0.0.1:5907 user@jenkins-agent
   ```

В режиме Jenkins `onec-wait-ready` проверяет Xvfb. Готовность подключения
по VNC проверяйте в VNC-клиенте.

При переходе со старого образа удалите `VNC_PASSWORD_FILE` и монтирование
файла пароля из команды запуска.

## Настройки и зависимости

В `/opt/1cv8/conf/conf.cfg`:

```ini
DisableUnsafeActionProtection=.*
SystemLanguage=RU
```

В `/opt/1cv8/common/1cestart.cfg`: `UseHWLicenses=0`.
При запуске обоих образов параметр `ONEC_USE_HW_LICENSES` задаёт поиск
аппаратного ключа: `0` (по умолчанию, если переменной нет) или `1`.
Пустое или другое значение останавливает запуск с ошибкой.

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -e ONEC_USE_HW_LICENSES=1 \
  "$TEST_IMAGE" vrunner --help
```

Entrypoint записывает выбранное значение в
`$HOME/.1C/1cestart/1cestart.cfg` (UTF-16LE). По документации 1С пользовательский
файл имеет приоритет над общим: в `/opt` остаётся `0`, а действующее значение
задаётся в пользовательском файле. Остальные пользовательские параметры
сохраняются; при первом запуске берутся параметры общего файла, если он есть.
Уже существующий UseHWLicenses заменяется также при запуске без переменной.
Не подключайте отдельный пользовательский cfg как bind mount или symlink:
entrypoint атомарно заменяет обычный доступный для записи файл. Для сохранения
настроек подключайте доступный для записи HOME или каталог конфигурации. Для контейнеров с
разными настройками используйте отдельные HOME. Менять переменную нужно
при создании нового контейнера. Root не требуется; UID/GID Jenkins поддерживаются.
Пример pipeline содержит параметр выбора `0`/`1`.

Источник: [руководство 1С 8.3.27, приложение 3.6](https://1c-dn.com/library/tutorials/1c_enterprise_administrator_guide_file_mode_8_3_27/).

Отключение защиты небезопасных действий запрошено для тестового окружения.
В onec-test также задан параметр полнотекстового поиска v2 для Java 17:
`FtsJavaOpts=--add-opens java.base/java.lang=ALL-UNNAMED`.

Состав и версии: [docs/dependencies.md](docs/dependencies.md).
Сборка устанавливает Microsoft Core Fonts с принятием EULA пакета.
Платформа, лицензии и доступ к порталу предоставляются пользователем;
образы не включают лицензию 1С. Smoke-тесты проверяют инструменты и права,
но не заменяют тестирование вашей конфигурации с лицензией.

## Записи проекта

- [Актуальное состояние и решения](docs/PROJECT.md)
- [Журнал проекта](docs/CHANGELOG.md)
- [Спецификация](docs/superpowers/specs/2026-10-23-docker-images-design.md)
