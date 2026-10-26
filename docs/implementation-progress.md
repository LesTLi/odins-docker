# Реализация плана images-actions

План: docs/superpowers/plans/2026-10-23-images-actions.md.
2026-10-23: пользователь подтвердил план и последовательное выполнение.

Ruling: работа в текущем checkout на отдельной feat/images-actions —
сохраняет уже написанные документы и не создаёт лишнюю копию пустого проекта.
Ruling: тесты выполняются только в Actions по требованию пользователя;
для RED/GREEN публикуются промежуточные коммиты рабочей ветки.
Pre-flight: acquire → install используют нормализованный каталог;
build → smoke используют локальный тег Docker на одном runner.
Задача 1: реализована, Check GREEN. Задачи 2–5: код реализован,
tools smoke GREEN, полная матрица платформы проверяется. Задача 6:
README/Jenkins/записи подготовлены; итоговый отчёт ожидает CI.

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
Ruling: локальный источник использует фиксированный distr/ в build context;
DIST_DIR не вводится, чтобы не усложнять интерфейс. CI экспортирует туда
проверенный дистрибутив. configure-platform.sh принимает только IMAGE;
версионная конфигурация доступна через /opt/1cv8/current.
Ruling: пример Jenkins использует docker run, поскольку docker exec внутри
inside() не наследует HOME/NSS/DISPLAY, выставленные entrypoint.
Ревью выявило потерю stdin в асинхронной команде; добавлен регрессионный
smoke-тест и явное сохранение fd перед background запуском.

Actions 39896440039 и 39896443810: Check GREEN (ShellCheck, Hadolint,
actionlint, входные данные, идемпотентность конфигурации/ConfLocation).
Независимое ревью выполнено: исправлен пример Jenkins, сохранён stdin;
добавлена обязательность клиентских бинарников и проверка TERM после
сигнала готовности дочерней команды. Новые проверки ожидают запуска CI.

Actions 39897250336 и 39897790928: оба tools GREEN со всеми smoke. Полная матрица RED до обращения к порталу: Fluent из OPM не содержит lambdas. Добавлена проверка yard --help до секретов; Fluent 0.6.1 переустанавливается с зависимостями. Безопасная диагностика скачивания выводит только фиксированные категории ошибок. Повторное read-only ревью f15e084: новых blocker нет.

2026-10-26: реализация завершена. Официальный YARD 1.14.0 работает в отдельном OneScript 2.2.0 downloader; конечный onec-test сохраняет OneScript 1.9.4/Vanessa Runner 2.6.1. Диск runner освобождён до 35 GiB; временные дистрибутивы перемещаются без лишних копий. Настоящий RUN --help проверен, optional/client компоненты server явно отключены. Actions 40258325298 (dd167b4): tools и вся полная матрица GREEN, восемь PASS для download/local. Check 40258329813 GREEN. Финальное независимое ревью dd167b4: новых ошибок нет. Все исполняемые проверки выполнялись только в Actions. Интерфейс сборки использует distr/; прототип DIST_DIR не вводился. Merge, registry и тестирование пользовательской конфигурации остаются отдельными этапами.

2026-10-26 — versioned artifacts: схема подтверждена, план docs/superpowers/plans/2026-10-26-versioned-artifacts.md. RED helper: Actions 40263251522. Реализация 05f6bff; Check 40264262093 GREEN после отдельного Docker fixture с реальным слоем (полностью пустой scratch не поддерживается docker save). Проверены версии/отказ неверного Git-тега/rerun/manual gate, защита provenance/существующего каталога, реальный save/load двух релизных тегов и SHA256/JSON. Независимое ревью d29a17e: важных ошибок нет. Полная матрица 40264043012 ещё выполняется. Ruling: один экспорт local после обеих smoke-веток; release alias только push тега attempt1, rerun/dispatch только уникальный тег; registry и GitHub Release не публикуются.

Actions 40264043012: server/deb и server/run прошли обе сборки, save/load и upload; onec-test/run также успешно экспортирован и загружен. onec-test/deb завершился 141 после проверок local. В smoke обнаружен возможный SIGPIPE от docker logs | grep -q под pipefail; независимое ревью подтвердило механизм (точный участок старого падения без trace не доказан). Обе проверки переведены на log file + grep, добавлен ERR line/status; полная матрица повторяется.
