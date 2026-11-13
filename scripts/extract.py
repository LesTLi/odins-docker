"""Normalize vendor distributions without trusting archive paths or symlinks."""
import pathlib
import shutil
import sys
import tarfile
import zipfile


def extract(source, destination):
    count = 0

    def save(name, stream):
        nonlocal count
        name = pathlib.PurePosixPath(name).name
        if not name.endswith(('.deb', '.run')):
            return
        count += 1
        target = destination / str(count)
        target.mkdir()
        with (target / name).open('wb') as output:
            shutil.copyfileobj(stream, output)

    for path in sorted(source.rglob('*')):
        if path.is_symlink() or not path.is_file():
            continue
        if path.name.endswith(('.deb', '.run')):
            with path.open('rb') as stream:
                save(path.name, stream)
        elif path.name.endswith(('.tar.gz', '.tgz', '.tar.xz')):
            with tarfile.open(path) as archive:
                for member in archive:
                    if member.isfile():
                        with archive.extractfile(member) as stream:
                            save(member.name, stream)
        elif path.suffix == '.zip':
            with zipfile.ZipFile(path) as archive:
                for member in archive.infolist():
                    if not member.is_dir() and (member.external_attr >> 16) & 0o170000 != 0o120000:
                        with archive.open(member) as stream:
                            save(member.filename, stream)


if __name__ == '__main__':
    extract(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
