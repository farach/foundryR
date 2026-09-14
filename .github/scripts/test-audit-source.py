import io
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("audit-source.py")
NAMESPACE = (
    "S3method(print,foundry_codebook_diff)\n"
    "S3method(format,foundry_codebook_diff)\n"
)


def make_archive(path, extra=None):
    files = {"foundryR/NAMESPACE": NAMESPACE, **(extra or {})}
    with tarfile.open(path, "w:gz") as archive:
        for name, content in files.items():
            data = content.encode()
            info = tarfile.TarInfo(name)
            info.size = len(data)
            archive.addfile(info, io.BytesIO(data))


class SourceAuditChecks(unittest.TestCase):
    def audit(self, path):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(path)],
            text=True, capture_output=True, check=False,
        )

    def test_safe_archive_and_checksum_mismatch(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "foundryR_0.1.0.tar.gz"
            make_archive(path)
            self.assertEqual(self.audit(path).returncode, 0)
            self.assertEqual(self.audit(path).returncode, 0)
            with path.open("ab") as output:
                output.write(b"changed")
            result = self.audit(path)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("checksum", result.stderr)

    def test_internal_help_and_private_files_are_rejected(self):
        for name in (
            "foundryR/man/batch_vector.Rd",
            "foundryR/.Renviron",
            "foundryR/tests/manual/test_live.R",
            "foundryR/vignettes/audio/0/response.R",
        ):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "foundryR_0.1.0.tar.gz"
                make_archive(path, {name: "excluded"})
                self.assertNotEqual(self.audit(path).returncode, 0)


if __name__ == "__main__":
    unittest.main()
