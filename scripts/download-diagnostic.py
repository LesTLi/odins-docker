"""Report only predefined error categories, never vendor log content or secrets."""
import pathlib
import re
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
# Печатаем только заранее выбранные признаки, без строк из лога YARD.
signals = {
    "timeout": r"timed?\s*out|timeout|тайм[- ]?аут|время ожидания",
    "request-cancelled": r"operation (?:was )?cancell?ed|task was cancell?ed",
    "dns": r"could not resolve|name or service not known|no such host|имя узла не",
    "connection-reset": r"connection reset|соединение.*сброшено",
    "connection-refused": r"connection refused|отказано в подключении",
    "incomplete-response": r"response ended prematurely|unexpected eof|unexpected end of (?:stream|file)",
}
matched = [name for name, pattern in signals.items() if re.search(pattern, log)]
print("Network details: " + (", ".join(matched) or "unclassified"))
statuses = sorted(set(re.findall(r"(?:кодвозврата|http (?:status|response) code)\s*:\s*([45][0-9]{2})\b", log)))
if statuses:
    print("HTTP error status: " + ", ".join(statuses))
print(f"Vendor log characters: {len(log)}")
