import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "check_site", Path(__file__).with_name("check-site.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SiteChecks(unittest.TestCase):
    def test_links_anchors_assets_and_external_urls(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "index.html").write_text(
                '<a href="topic.html#section">Topic</a>'
                '<a href="https://example.net/elsewhere">External</a>'
                '<script src="site.js"></script>',
                encoding="utf-8",
            )
            (root / "topic.html").write_text(
                '<h1 id="section">Topic</h1>'
                '<a href="/package/index.html">Home</a>',
                encoding="utf-8",
            )
            (root / "site.js").write_text("", encoding="utf-8")
            self.assertEqual(module.check_site(root, "https://example.org/package/"), [])

    def test_broken_target_and_fragment(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "index.html").write_text(
                '<img src="missing.png"><a href="#absent">Missing section</a>',
                encoding="utf-8",
            )
            errors = module.check_site(root, "https://example.org/package/")
            self.assertEqual(len(errors), 2)
            self.assertIn("missing target", errors[0])
            self.assertIn("missing anchor", errors[1])


if __name__ == "__main__":
    unittest.main()
