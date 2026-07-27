#!/usr/bin/env python3
"""
albums_by_year.py

Read an iTunes/Apple Music "Library.xml" file, collate tracks into albums,
and produce a Markdown file listing albums grouped by year (most recent
year among an album's tracks is used), optionally filtered by genre.

Usage:
    python albums_by_year.py -s <path-to-Library.xml> [-d <output.md>] [genre1] [genre2] ...

    -s / --source   Required. Path to the iTunes-style XML file.
    -d / --dest     Optional. Path to the Markdown file to write.
                    Defaults to the source filename with a .md extension.

    Any remaining (unflagged) arguments are treated as genre labels.
    If any genres are given, only albums whose tracks include at least
    one of those genres are included. If none are given, all genres
    are included.

Output:
    A Markdown file with:
        # <Year>
        - Album Name — *Album Artist*
    sorted by year descending, and albums sorted alphabetically within
    each year.

    A [WARNING] is printed for every track that has no genre set, e.g.:
        [WARNING] Track {track name} of album {album name} by {album artist name} has no genre
"""

import argparse
import os
import plistlib
import sys
from collections import defaultdict


def load_tracks(xml_path):
    """Parse the iTunes-style plist XML and return the dict of tracks."""
    with open(xml_path, "rb") as f:
        library = plistlib.load(f)
    return library.get("Tracks", {})


def collate_albums(tracks, genre_filter=None):
    """
    Group tracks by (Album, Album Artist), collecting the set of genres
    seen and the most recent year seen for that album.

    genre_filter: a set of genre strings (case-insensitive) to include,
                  or None/empty to include all genres.

    Returns a dict keyed by (album_name, album_artist) -> {
        "year": int or None,
        "genres": set of genres seen for this album
    }
    """
    albums = defaultdict(lambda: {"year": None, "genres": set()})

    genre_filter_lower = None
    if genre_filter:
        genre_filter_lower = {g.lower() for g in genre_filter}

    for track in tracks.values():
        album = track.get("Album")
        if not album:
            # Skip tracks with no album info (e.g. podcasts, voice memos)
            continue

        album_artist = (
            track.get("Album Artist")
            or track.get("Artist")
            or "Unknown Artist"
        )

        genre = track.get("Genre")
        if not genre:
            track_name = track.get("Name", "Unknown Track")
            show_warning(f"Track {track_name} of album {album} by {album_artist} has no genre")

        year = track.get("Year")
        # Fall back to extracting year from "Release Date" if "Year" missing
        if not year:
            release_date = track.get("Release Date")
            if release_date and hasattr(release_date, "year"):
                year = release_date.year

        key = (album, album_artist)
        entry = albums[key]

        if genre:
            entry["genres"].add(genre)

        if year:
            if entry["year"] is None or year > entry["year"]:
                entry["year"] = year

    # Apply genre filter, if any, after collation (an album qualifies if
    # ANY of its tracks' genres match the requested set).
    if genre_filter_lower:
        filtered = {}
        for key, entry in albums.items():
            entry_genres_lower = {g.lower() for g in entry["genres"]}
            if entry_genres_lower & genre_filter_lower:
                filtered[key] = entry
        albums = filtered

    return albums


def build_markdown(albums):
    """
    Build the Markdown text: level-1 headings per year (descending),
    with a bullet list of albums (alphabetical) below each, each
    suffixed with the album artist in italics.
    """
    by_year = defaultdict(list)
    unknown_year_albums = []
    total = 0

    for (album, album_artist), entry in albums.items():
        year = entry["year"]
        total += 1
        if year:
            by_year[year].append((album, album_artist))
        else:
            unknown_year_albums.append((album, album_artist))

    lines = ["# Albums by Year", "", f"**{total} albums**", ""]

    for year in sorted(by_year.keys(), reverse=True):
        lines.append(f"# {year}")
        lines.append("")

        entries = []
        count = 0
        for album, album_artist in sorted(by_year[year], key=lambda x: x[0].lower()):
            entries.append(f"* {album} — *{album_artist}*")
            count += 1

        lines.append(f"*{count} albums*")
        lines.append("")
        lines.extend(entries)
        lines.append("")

    if unknown_year_albums:
        lines.append("# Unknown Year")
        lines.append("")
        entries = []
        count = 0

        for album, album_artist in sorted(unknown_year_albums, key=lambda x: x[0].lower()):
            entries.append(f"* {album} — *{album_artist}*")
            count +=1

        lines.append(f"*{count} albums*")
        lines.append("")
        lines.extend(entries)
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"

def show_warning(msg: str):
    output("[WARNING]", msg)

def show_error(msg: str):
    output("[ERROR]", msg)

def output(type: str, msg: str):
    if type:
        print(f"{type} {msg}")
    else:
        print(msg)

def main():
    parser = argparse.ArgumentParser(description="Generate a Markdown list of albums grouped by year from an iTunes/Apple Music Library.xml file.", add_help=True)
    _ = parser.add_argument("-s", "--source", help="Path to the source Library.xml file")
    _ = parser.add_argument("-d", "--dest", help="Path to the output Markdown file (defaults to the source filename with a .md extension)")
    _ = parser.add_argument("genres", nargs="*", help="Zero or more genre labels to filter by (all genres included if none given)")

    args = parser.parse_args()
    if not args.source:
        show_error("No source file provided. Use -s <path-to-Library.xml>.")
        sys.exit(1)

    xml_path = args.source

    if not os.path.isfile(xml_path):
        show_error(f"Source file not found: {xml_path}")
        sys.exit(1)

    dest_path = args.dest or (os.path.splitext(xml_path)[0] + ".md")

    genre_args = args.genres

    tracks = load_tracks(xml_path)
    albums = collate_albums(tracks, genre_filter=genre_args if genre_args else None)

    if not albums:
        print("No albums found matching the given criteria.")
        sys.exit(0)

    markdown = build_markdown(albums)

    with open(dest_path, "w", encoding="utf-8") as f:
        f.write(markdown)

    print(f"Wrote {len(albums)} album(s) to {dest_path}")

if __name__ == "__main__":
    main()
