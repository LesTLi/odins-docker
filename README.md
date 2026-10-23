# odins-docker

Два самостоятельных образа Linux amd64 для платформы **8.3.27.2130**:

| Образ | Назначение |
| --- | --- |
| `server` | `ibcmd`, компоненты common/server, без автозапуска кластера |
| `onec-test` | Полный клиент, конфигуратор, OneScript, Vanessa Runner 2.6.1, ADD, Java 17, Xvfb и VNC |

Код находится на этапе проверки в GitHub Actions. Результаты реальных
сборок отражены в [состоянии проекта](docs/PROJECT.md); наличие Dockerfile
само по себе не подтверждает успешную сборку.

## GitHub Actions

Сборка и тестирование выполняются на GitHub-hosted Ubuntu runner.
Локальный Docker для разработки проекта не требуется.

1. В Settings → Secrets and variables → Actions добавьте secrets
   `ONEC_USERNAME` и `ONEC_PASSWORD` учётной записи с доступом к релизу 1С.
2. Workflow **Check** проверяет Bash, входные дистрибутивы, Dockerfile и YAML.
3. **Build and test** сначала собирает зависимости без платформы и проверяет
   non-root запуск. Затем собирает оба образа в форматах DEB и RUN,
   проверяя download и local на runner.
4. Сборка запускается при push в main и рабочую ветку feat/images-actions.
   После появления workflow в main доступен Actions → Build and test →
   Run workflow с указанием версии платформы.

Отсутствующие secrets приводят к ошибке, а не к успешному пропуску сборки.
Дистрибутивы и готовые образы пока не публикуются в registry или artifacts.
GitHub runner удаляется после job. Для использования результата Jenkins
потребуется отдельно настроить приватный registry и публикацию после тестов.

## Источник и формат дистрибутива

`DIST_SOURCE=local|download` выбирает источник; `INSTALL_FORMAT=deb|run`
выбирает способ установки. По умолчанию используются local и deb.
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
docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$PWD,dst=/workspace" \
  odins-server:8.3.27.2130-deb ibcmd --help

docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$PWD,dst=/workspace" \
  odins-onec-test:8.3.27.2130-run vrunner --help
```

По умолчанию UID/GID — 10001:10001. Для Jenkins передавайте UID/GID
пользователя агента, которому принадлежит workspace. Произвольный UID
поддерживается через nss_wrapper; при недоступном HOME создаётся приватный
временный каталог. Для сохранения пользовательских данных смонтируйте
доступный этому UID домашний каталог и задайте HOME.

Контейнер не меняет владельца смонтированного workspace. 1С создаёт файлы
с правами 0660: для нескольких UID используйте общую группу и setgid
каталога базы на хосте. CIFS монтируйте на хосте без nobrl, а в Samba
не используйте locking=no. Пример pipeline: [examples/Jenkinsfile](examples/Jenkinsfile).

Пример использует docker run для всей команды тестирования. Шаги docker exec
и Jenkins docker.image(...).inside() не наследуют переменные, установленные
entrypoint (HOME, NSS, DISPLAY), поэтому напрямую их здесь не используем.

## Графические тесты

onec-test запускает Xvfb автоматически; DISPLAY по умолчанию :99,
XVFB_SCREEN — 1440x900x24. Для снимка экрана:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$PWD:/workspace" odins-onec-test:8.3.27.2130-run \
  nircmd savescreenshot '/workspace/screen shot.png'
```

VNC выключен по умолчанию. Создайте пароль-файл командой `x11vnc -storepasswd`
интерактивно и смонтируйте его read-only с правом чтения для UID контейнера.
Включите `ENABLE_VNC=1`, укажите `VNC_PASSWORD_FILE=/run/vnc-password` и
публикуйте порт **только на localhost**: `-p 127.0.0.1:5900:5900`.
Для удалённого доступа используйте SSH-туннель. Не храните пароль-файл в Git.

## Настройки и зависимости

В `/opt/1cv8/conf/conf.cfg`:

```ini
DisableUnsafeActionProtection=.*
SystemLanguage=RU
```

В `/opt/1cv8/common/1cestart.cfg`: `UseHWLicenses=0`.
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
