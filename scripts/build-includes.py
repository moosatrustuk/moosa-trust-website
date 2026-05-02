#!/usr/bin/env python3
"""Apply shared HTML fragments to every page.

Each HTML file marks where a fragment should be rendered with paired comments:

    <!-- include:nav-subpage -->
    ...current rendered content...
    <!-- /include:nav-subpage -->

This script reads the include name from the opening marker, replaces everything
between the markers with the matching file from `_includes/<name>.html`, and
writes the page back. Markers are preserved so the file remains self-serving on
GitHub Pages and the script can be re-run any time.

Usage:
    python3 scripts/build-includes.py

Add a new shared fragment by:
    1. Dropping it into _includes/<name>.html
    2. Wrapping the equivalent block in each HTML file with
       <!-- include:<name> --> ... <!-- /include:<name> -->
    3. Re-running this script.
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
INCLUDES = os.path.join(ROOT, "_includes")

OPEN_RE = re.compile(r'<!--\s*include:([a-z0-9-]+)\s*-->')
PAIR_RE = re.compile(
    r'<!--\s*include:([a-z0-9-]+)\s*-->.*?<!--\s*/include:\1\s*-->',
    re.DOTALL,
)


def render(html: str, source_path: str) -> str:
    def repl(m: re.Match) -> str:
        name = m.group(1)
        frag_path = os.path.join(INCLUDES, f"{name}.html")
        if not os.path.exists(frag_path):
            print(
                f"  WARN: {source_path}: include '{name}' not found "
                f"(expected {frag_path})",
                file=sys.stderr,
            )
            return m.group(0)
        with open(frag_path) as f:
            frag = f.read().rstrip("\n")
        return f"<!-- include:{name} -->\n{frag}\n<!-- /include:{name} -->"

    return PAIR_RE.sub(repl, html)


def main() -> int:
    targets = []
    for dirpath, _dirs, filenames in os.walk(ROOT):
        # Skip hidden dirs and the includes folder itself
        if "/.git" in dirpath or dirpath.endswith("/_includes"):
            continue
        for name in filenames:
            if name.endswith(".html"):
                targets.append(os.path.join(dirpath, name))

    changed = 0
    for path in sorted(targets):
        with open(path) as f:
            original = f.read()
        if not OPEN_RE.search(original):
            continue
        rendered = render(original, path)
        if rendered != original:
            with open(path, "w") as f:
                f.write(rendered)
            changed += 1
            print(f"  rendered: {os.path.relpath(path, ROOT)}")

    print(f"\n{changed} file(s) updated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
