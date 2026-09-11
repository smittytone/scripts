#!/usr/bin/env python3
"""
Split a markdown/text file into multiple files, one per level-1 heading.

Usage:
    python3 split_markdown.py --base chapter path/to/file.md
    python3 split_markdown.py --base chapter --output build/ file.md

Each level-1 heading ("# Some Title") starts a new output file; everything
until the next level-1 heading (or end of file) belongs to that file. Output
files are named "<base>-<n>.<ext>", where <n> is a zero-padded, 1-based
index (padded to the width of the total file count) and <ext> matches the
source file's extension.
"""
import argparse
import platform
import re
import sys
from pathlib import Path
from typing import NoReturn


# Reporting functions
ANSI_BOLD_RED = "\033[1;31m"
ANSI_BOLD_YELLOW = "\033[1;33m"
ANSI_BOLD_GREEN = "\033[1;32m"
ANSI_RESET = "\033[0m"


def colour_tag(tag: str, ansi_colour: str) -> str:
    if not sys.stderr.isatty():
        return tag
    return f"{ansi_colour}{tag}{ANSI_RESET}"


def use_emoji_labels() -> bool:
    return platform.system() != "Linux"


def report_error(message: str) -> None:
    tag = "⛔️" if use_emoji_labels() else colour_tag("[ERROR]", ANSI_BOLD_RED)
    print(f"{tag} {message}", file=sys.stderr)


def report_error_and_exit(message: str, code: int = 1) -> NoReturn:
    report_error(message)
    sys.exit(code)


def report_warning(message: str) -> None:
    tag = "⚠️ " if use_emoji_labels() else colour_tag("[WARNING]", ANSI_BOLD_YELLOW)
    print(f"{tag} {message}", file=sys.stderr)


def report_info(message: str) -> None:
    tag = "💬" if use_emoji_labels() else colour_tag("[INFO]", ANSI_BOLD_GREEN)
    print(f"{tag} {message}", file=sys.stderr)


# Constants
ALLOWED_EXTENSIONS = {".md", ".txt", ".text"}
HEADING1_RE = re.compile(r"^#\s+.+?\s*$")


def split_sections(text: str) -> list[str]:
    """
    Split `text` into sections, each starting at a level-1 heading line.
    Any content before the first level-1 heading is discarded (there is no
    heading to anchor it to).
    """
    lines = text.splitlines(keepends=True)
    sections: list[list[str]] = []
    current: list[str] | None = None

    for line in lines:
        if HEADING1_RE.match(line):
            if current is not None:
                sections.append(current)
            current = [line]
        elif current is not None:
            current.append(line)

    if current is not None:
        sections.append(current)

    return ["".join(section) for section in sections]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", help="Path to the markdown/text file to split (absolute, relative, or a filename in the current directory)")
    parser.add_argument("--base", required=True, help="Filename base for output files, e.g. 'chapter' -> chapter-01.md, chapter-02.md, ...")
    parser.add_argument("--output", default=None, help="Directory to write output files into (default: the current working directory)")
    args = parser.parse_args()

    source_path = Path(args.source).expanduser()
    if not source_path.exists():
        report_error_and_exit(f"source file not found: {source_path}")
    if not source_path.is_file():
        report_error_and_exit(f"source path is not a file: {source_path}")

    if source_path.suffix.lower() not in ALLOWED_EXTENSIONS:
        report_error_and_exit(
            f"unsupported file type {source_path.suffix!r}; expected one of {sorted(ALLOWED_EXTENSIONS)}"
        )

    output_dir = Path(args.output).expanduser() if args.output else Path(".")
    if output_dir.exists() and not output_dir.is_dir():
        report_error_and_exit(f"output path is not a directory: {output_dir}")
    if not output_dir.exists():
        report_error_and_exit(f"output directory not found: {output_dir}")

    text = source_path.read_text(encoding="utf-8")
    sections = split_sections(text)

    if not sections:
        report_warning(f"no level-1 headings found in {source_path}")
        sys.exit(0)

    width = len(str(len(sections)))
    ext = source_path.suffix

    for i, section in enumerate(sections, start=1):
        out_path = output_dir / f"{args.base}-{i:0{width}d}.md"
        out_path.write_text(section, encoding="utf-8")


if __name__ == "__main__":
    main()
