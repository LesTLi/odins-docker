"""Report only predefined error categories, never vendor log content or secrets."""
import pathlib
import sys

log = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").lower()
categories = {
    "missing-library": ("не найдена библиотека", "библиотека не найдена", "library not found"),
    "unknown-argument": ("неизвестный параметр", "unknown option", "unknown argument"),
    "missing-method": ("метод объекта не обнаружен", "method not found"),
    "authentication": ("авторизац", "аутентификац", "authentication", "unauthorized", "401"),
    "forbidden": ("403", "forbidden", "доступ запрещен", "доступ запрещён"),
    "tls": ("ssl", "tls", "certificate", "сертификат"),
    "network": ("timeout", "timed out", "resolve", "connect", "соединени"),
    "no-match": ("не найден", "не найдены", "not found"),
    "encoding": ("encoding", "кодировк"),
    "version-selected": ("загрузка версии",),
    "distribution-link-missing": ("не найдена ссылка на дистрибутив",),
    "download-started": ("начало загрузки",),
    "file-downloaded": ("загружен файл",),
    "file-extracted": ("распакован файл",),
    "processing-completed": ("завершение обработки данных",),
}
found = [name for name, patterns in categories.items() if any(p in log for p in patterns)]
print("Download diagnostic categories: " + (", ".join(found) or "unclassified"))
