import argparse
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.anchors = set()
        self.links = []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for name in ("id", "name"):
            if attrs.get(name):
                self.anchors.add(attrs[name])
        for name in ("href", "src"):
            if attrs.get(name):
                self.links.append(attrs[name])


def check_site(root, site_url):
    root = root.resolve()
    site = urlsplit(site_url)
    pages = {
        path.resolve(): Page(path.read_text(encoding="utf-8"))
        for path in root.rglob("*.html")
    }
    errors = []
    if root / "index.html" not in pages:
        return ["Site index.html is missing."]
    for path, page in pages.items():
        for link in page.links:
            target = urlsplit(link)
            if target.scheme not in ("", "http", "https"):
                continue
            if target.netloc and target.netloc != site.netloc:
                continue
            decoded = unquote(target.path)
            if decoded.startswith("/") or target.netloc:
                if not decoded.startswith(site.path):
                    continue
                destination = root / decoded[len(site.path):]
            elif decoded:
                destination = path.parent / decoded
            else:
                destination = path
            destination = destination.resolve()
            if destination.is_dir():
                destination /= "index.html"
            if not destination.is_relative_to(root) or not destination.is_file():
                errors.append(f"{path.relative_to(root)}: missing target {link}")
            elif target.fragment and destination in pages:
                fragment = unquote(target.fragment)
                if fragment not in pages[destination].anchors:
                    errors.append(f"{path.relative_to(root)}: missing anchor {link}")
    print(f"Checked {len(pages)} HTML pages and their local links, anchors, and assets.")
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("--site-url", required=True)
    args = parser.parse_args()
    problems = check_site(args.directory, args.site_url)
    for problem in problems:
        print(problem)
    raise SystemExit(bool(problems))
