# Версионирование и TAR-артефакты

Требования обновлены владельцем 2026-10-27. Результаты проверок — PROJECT.md.

## Версии и имена

IMAGE_VERSION=1.0 — версия проекта из versions.env: два числовых компонента
без начальных нулей. Это собственная схема MAJOR.MINOR, не полный SemVer.
Совместимые исправления/дополнения: 1.0 → 1.1; несовместимые изменения:
1.x → 2.0. ONEC_VERSION=8.3.27.2130 — отдельная версия платформы из файла;
manual input version позволяет переопределить её на один запуск.

INSTALL_FORMAT=deb в versions.env выбирает единственный формат для обоих
образов: deb или run. В Actions нет отдельного input выбора формата;
и разработка, и выпуск используют файл из выбранного commit/ref.
Прямой вызов scripts/build.sh сохраняет возможность явного env override.

Разработка:

- onec-test:1.0-1c8.3.27.2130-b40265588178
- onec-server:1.0-1c8.3.27.2130-b40265588178

Выпуск:

- onec-test:1.0-1c8.3.27.2130
- onec-server:1.0-1c8.3.27.2130

У релизного образа сохраняются оба тега: тег запуска и итоговый. Они
указывают на один проверенный image ID, без пересборки для назначения тега.
Имя релизного artifact/TAR использует итоговый тег, например
onec-test_1.0-1c8.3.27.2130.tar. У разработческого TAR остаются
номер запуска, но не формат установки.

## Когда собирается выпуск

Сохранён существующий механизм Git-тегов: push тега v1.0, точно совпадающего
с IMAGE_VERSION=1.0. Это выбор исполнителя для момента выпуска; пользователь
поручил определить его. Неверные версии/refs/форматы отклоняет plan до сборки.

| Событие | Форматы | Теги |
| --- | --- | --- |
| Push файлов сборки в feat/images-actions | Из versions.env | Для разработки |
| Push изменений в main | Образы 1С не собираются; только Check | — |
| Push Git-тега vX.Y | Из versions.env | Для разработки и итоговый |
| Ручной запуск на ветке | Из versions.env | Для разработки |
| Ручной запуск на Git-теге vX.Y | Из versions.env | Для разработки и итоговый |

Каждый запуск сборки проверяет download/local и оба образа: четыре
сборки/smoke и два TAR в выбранном формате.
После успешных smoke финальные теги назначаются уже проверенному кандидату.

Порядок выпуска: повысить IMAGE_VERSION, проверить ветку в Actions, включить
изменения в main, затем создать и отправить Git-тег vX.Y. Git-теги и merge
в этой задаче автоматически не выполняются. Создание тега не создаёт
GitHub Release. Ручной workflow должен присутствовать в default branch main.
Для запуска с Git-тега через GitHub CLI: --ref v1.0. Формат читается из
versions.env на этом теге. Это инструкция, CLI здесь не запускается.

Пример ручного выпуска с существующего тега после появления workflow в main:

```bash
gh workflow run build.yml --repo LesTLi/odins-docker --ref v1.0
```

## Повторные попытки и неизменяемость

GITHUB_RUN_ATTEMPT не входит в тег, но остаётся в JSON. Повторная попытка
одного запуска имеет тот же тег/имя artifact; overwrite:true заменяет
прежний artifact этого запуска. Попытки различаются по run_attempt,
image ID и SHA256 TAR. Новый запуск получает другой b<run-id>.

При изменении состава повышать версию проекта; выпущенные Git-теги не
переносить. Изменение INSTALL_FORMAT также меняет состав образа и требует
новой версии проекта/тега. Формат записан в metadata и labels.
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

## Обсуждение latest, пока не реализовано

latest — дополнительный изменяемый тег того же проверенного image ID,
отдельная сборка не нужна. Возможное применение: назначать его вместе с
итоговым тегом явно выбранному актуальному стабильному выпуску; development
не получает latest. Явное назначение защищает от случайного продвижения
старого выпуска при rerun. В TAR можно сохранить оба тега, а в будущем
в Harbor публиковать их для того же образа. Пока добавление latest не
подтверждено; пользователь запросил объяснение возможной схемы.

## Первичные источники

- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- https://github.com/actions/upload-artifact#overwriting-an-artifact
- https://github.com/opencontainers/image-spec/blob/main/annotations.md
- https://docs.docker.com/guides/golang/

Подробное исследование и порядок работы с latest —
[releases-and-latest.md](releases-and-latest.md). Это описание вариантов,
назначение latest и публикация в registry в коде не добавлены.
