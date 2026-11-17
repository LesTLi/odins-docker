import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('extract', Path(__file__).parents[1] / 'scripts/extract.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ExtractTests(unittest.TestCase):
    def test_tar_keeps_payload_without_following_links_or_archive_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, output = root / 'input', root / 'out'
            source.mkdir()
            output.mkdir()
            with tarfile.open(source / 'packages.tar.gz', 'w:gz') as archive:
                payload = tarfile.TarInfo('../../outside.deb')
                payload.size = 4
                archive.addfile(payload, io.BytesIO(b'data'))
                link = tarfile.TarInfo('link.deb')
                link.type = tarfile.SYMTYPE
                link.linkname = '/etc/passwd'
                archive.addfile(link)
            module.extract(source, output)
            self.assertFalse((root / 'outside.deb').exists())
            files = list(output.rglob('*.deb'))
            self.assertEqual(len(files), 1)
            self.assertEqual(files[0].read_bytes(), b'data')

    def test_zip_preserves_duplicate_installers_for_ambiguity_detection(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, output = root / 'input', root / 'out'
            source.mkdir()
            output.mkdir()
            with zipfile.ZipFile(source / 'setup.zip', 'w') as archive:
                archive.writestr('a/setup.run', b'first')
                archive.writestr('b/setup.run', b'second')
                archive.writestr('readme.txt', b'ignore')
            module.extract(source, output)
            self.assertEqual(sorted(p.read_bytes() for p in output.rglob('*.run')), [b'first', b'second'])


if __name__ == '__main__':
    unittest.main()
