"""Count public catalog records; never print vendor response values."""
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if not path.is_file():
    print("Portal catalog: output file missing")
    sys.exit(1)
catalog = json.loads(path.read_text(encoding="utf-8-sig"))
if not isinstance(catalog, list):
    print("Portal catalog: unexpected schema")
    sys.exit(1)
platform = [item for item in catalog if isinstance(item, dict)
            and item.get("Идентификатор") == "Platform83"]
print(f"Portal catalog: applications={len(catalog)} platform83={len(platform)}")
