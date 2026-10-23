# Реализация плана images-actions

План: docs/superpowers/plans/2026-10-23-images-actions.md.
2026-10-23: пользователь подтвердил план и последовательное выполнение.

Ruling: работа в текущем checkout на отдельной feat/images-actions —
сохраняет уже написанные документы и не создаёт лишнюю копию пустого проекта.
Ruling: тесты выполняются только в Actions по требованию пользователя;
для RED/GREEN публикуются промежуточные коммиты рабочей ветки.
Pre-flight: acquire → install используют нормализованный каталог;
build → smoke используют локальный тег Docker на одном runner.
Задачи 1–6: в работе, ещё не проверены.

Actions 39894920259: RED — acquire.sh отсутствовал.
Actions 39895332531: выбор пакетов GREEN; ShellCheck выявил замечания.
Actions 39895772798: ShellCheck GREEN; исправляется вызов Hadolint.
Actions 39895772789: tools/server GREEN, включая UID/GID и workspace.
tools/onec-test: выявлены несовместимый встроенный OPM и отсутствие
add@6.9.5 в хабе. OPM закреплён 1.7.1, ADD берётся из GitHub release.
Actions 39896325079: RED — нет ConfLocation в версионном каталоге.
Ruling: использовать RUN компоненты server/client_full/client_thin_fib/ru
и отдельно проверять состав; эквивалентность ещё не подтверждена без сборки.
Ruling: полный CI запускается также push рабочей ветки для проверки до merge.
Ruling: пример Jenkins использует docker run, поскольку docker exec внутри
inside() не наследует HOME/NSS/DISPLAY, выставленные entrypoint.
Ревью выявило потерю stdin в асинхронной команде; добавлен регрессионный
smoke-тест и явное сохранение fd перед background запуском.
