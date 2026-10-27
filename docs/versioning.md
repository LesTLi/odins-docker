# Версионирование и TAR-артефакты

Требования обновлены владельцем 2026-10-27. Результаты проверок — PROJECT.md.

## Версии и имена

IMAGE_VERSION=1.0 — версия проекта из versions.env: два числовых компонента
без начальных нулей. Это собственная схема MAJOR.MINOR, не полный SemVer.
Совместимые исправления/дополнения: 1.0 → 1.1; несовместимые изменения:
1.x → 2.0. ONEC_VERSION=8.3.27.2130 — отдельная версия платформы из файла;
manual input version позволяет переопределить её на один запуск.

Разработка:

- onec-test:1.0-1c8.3.27.2130-run-b40265588178
- onec-server:1.0-1c8.3.27.2130-run-b40265588178

Выпуск:

- onec-test:1.0-1c8.3.27.2130
- onec-server:1.0-1c8.3.27.2130

У релизного образа сохраняются оба тега: тег запуска и итоговый. Они
указывают на один проверенный image ID, без пересборки для назначения тега.
Имя релизного artifact/TAR использует итоговый тег, например
onec-test_1.0-1c8.3.27.2130_linux-amd64.tar. У разработческого TAR остаются
формат и номер запуска.

## Когда собирается выпуск

Сохранён существующий механизм Git-тегов: push тега v1.0, точно совпадающего
с IMAGE_VERSION=1.0. Это выбор исполнителя для момента выпуска; пользователь
поручил определить его. Неверные версии/refs/форматы отклоняет plan до сборки.

| Событие | Форматы | Теги |
| --- | --- | --- |
| Push файлов сборки в main/feat/images-actions | DEB и RUN | Для разработки |
| Push Git-тега vX.Y | Только DEB | Для разработки и итоговый |
| Ручной запуск на ветке | Выбранный DEB/RUN, default DEB | Для разработки |
| Ручной запуск на Git-теге vX.Y | Выбранный DEB/RUN, default DEB | Для разработки и итоговый |

Каждый путь проверяет download/local и оба образа: push ветки даёт восемь
сборок/smoke и четыре TAR; выпуск/ручной запуск — четыре сборки/smoke и два TAR.
После успешных smoke финальные теги назначаются уже проверенному кандидату.

Порядок выпуска: повысить IMAGE_VERSION, проверить ветку в Actions, включить
изменения в main, затем создать и отправить Git-тег vX.Y. Git-теги и merge
в этой задаче автоматически не выполняются. Создание тега не создаёт
GitHub Release. Ручной workflow должен присутствовать в default branch main.
Для запуска с Git-тега через GitHub CLI: --ref v1.0; input install_format
задаёт deb/run. Это инструкция, CLI здесь не запускается.

Пример ручного RUN-выпуска с существующего тега после появления workflow в main:

```bash
gh workflow run build.yml --repo LesTLi/odins-docker --ref v1.0 -f install_format=run
```

## Повторные попытки и неизменяемость

GITHUB_RUN_ATTEMPT не входит в тег, но остаётся в JSON. Повторная попытка
одного запуска имеет тот же тег/имя artifact; overwrite:true заменяет
прежний artifact этого запуска. Попытки различаются по run_attempt,
image ID и SHA256 TAR. Новый запуск получает другой b<run-id>.

При изменении состава повышать версию проекта; выпущенные Git-теги не
переносить. Ручной выбор другого формата может дать другой image ID при
том же итоговом теге: фактический формат записан в metadata и labels.
Теги сами по себе не гарантируют неизменность байтов. Правила immutable
tags/digest для Harbor будут отдельной задачей интеграции registry.

## Доставка

В artifact: TAR, .tar.sha256, .metadata.json и size-report.txt. JSON:
версии, tags, формат, полный Git SHA, UTC-время, run ID/attempt, image ID,
SHA256 TAR. Проверяются docker save/load, tags, labels и image ID.
Labels: org.opencontainers.image.version/revision/source/created,
io.github.lestli.odins-docker.onec.version и
io.github.lestli.odins-docker.install.format.

Хранение private Actions Artifacts — один день. После проверки download/local
экспортируется local-кандидат. Registry/Harbor, latest, GHCR и GitHub Releases
не реализуются. Измерения DEB/RUN — [image-sizes.md](image-sizes.md).

## Первичные источники

- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- https://github.com/actions/upload-artifact#overwriting-an-artifact
- https://github.com/opencontainers/image-spec/blob/main/annotations.md
