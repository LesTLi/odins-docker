# Versioned TAR artifacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox syntax for tracking.

**Goal:** Выдавать из Actions проверенные TAR с различимыми версиями проекта, 1С и сборки.

**Architecture:** Общий Bash helper формирует теги и метаданные для build/export. После download/local smoke экспортируется один итоговый образ; релизный тег добавляется к нему без пересборки. Архив проверяется через docker load до загрузки в Actions artifacts.

**Tech Stack:** Bash, Python stdlib для JSON, Docker Buildx/save/load, GitHub Actions.

**Spec:** docs/versioning.md, подтверждена владельцем 2026-10-26.

## Global Constraints

- IMAGE_VERSION=1.0.0 независимо от ONEC_VERSION=8.3.27.2130.
- Полная матрица server/onec-test × deb/run × download/local сохраняется.
- Только GitHub Actions выполняет тесты; registry и merge не входят в этап.
- Выпуск vX.Y.Z должен совпадать с IMAGE_VERSION; новые сборки получают run ID + attempt.
- Секреты не включать в labels, JSON или архивы артефактов.
- Номер версии выпуска не перезаписывать; повторная попытка даёт только уникальный тег.

## Review Focus

- Повтор одного коммита: теги различаются по запуску и попытке.
- Ошибочный Git-тег: отказ до сборки, без короткого релизного тега.
- Экспорт: в TAR именно проверенный image ID; tags и labels переживают load.
- Частичный экспорт/повторная запись: существующий каталог артефакта не затирается.
- Большие образы: очистить завершённый BuildKit cache перед save, без удаления итогового образа.

## 1. Версии и provenance

- [ ] Добавить tests/test-versioning.sh и шаг Check; получить RED в Actions.
- [ ] Реализовать scripts/image-metadata.sh, IMAGE_VERSION в versions.env,
  параметры build.sh и OCI/custom labels обоих Dockerfile.
- [ ] Проверить stable SemVer, формат/платформу, Git SHA, release mismatch,
  run ID/attempt, отсутствие короткого тега у веток и rerun.

## 2. Экспорт и Actions

- [ ] scripts/export-image.sh: inspect/validate labels, tag, save,
  SHA256 и JSON, удалить выходные теги, load, сравнить image ID и labels.
- [ ] Добавить безопасный upload-artifact с уникальными именами и retention 1 день;
  trigger Git-тегов v*, ручной запуск и текущие push сохраняются.
- [ ] Выполнить полную матрицу, проверить четыре артефакта и roundtrip.
- [ ] Обновить README/PROJECT/CHANGELOG/spec и PR; финальное ревью.

Выполняется последовательно в текущей согласованной ветке feat/images-actions;
подтверждение схемы уже получено, дополнительного согласования не требуется.
