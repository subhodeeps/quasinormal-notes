#!/usr/bin/env python3
#
# Author(s): Subhodeep Sarkar
# Affiliation: IIT Gandhinagar and IIIT Allahabad
# Contact: subhodeep.sarkar1@gmail.com
# Date: October 2026
# Github: https://github.com/subhodeeps/quasinormal-notes

"""Write the icons of tools/calibre-slate.user.css from a Nerd Font.

calibre draws every icon of its web page as an inline SVG of the form
<svg><use xlink:href="#icon-home"/></svg>. A style sheet cannot swap
that for a character of a font, but it can hide the <use> and paint the
SVG element with its own colour through a mask. This script takes the
outline of a glyph of the Nerd Font for each icon in ICONS, turns it
into an SVG image, and writes one rule per icon, with the image as the
mask, between the two "icons:" markers of the style sheet. Run it again
after a change of ICONS or of the font:

    .venv/python/bin/python tools/calibre-nerd-icons.py [font.ttf]

The glyph names are those of the patched fonts, such as "md-home" for
the Material Design icon "home". Icons that ICONS leaves out, such as
those of the editor of the viewer, keep calibre's own look. The rules
use :has(), which Chrome, Brave, Safari and Firefox support in their
current versions.
"""

import sys
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

FONT = Path.home() / "Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
CSS = Path(__file__).with_name("calibre-slate.user.css")
BEGIN = "    /* icons: begin (written by tools/calibre-nerd-icons.py) */"
END = "    /* icons: end */"

# calibre's icon name -> the names of the glyph to try, in order
ICONS = {
    "home": ["md-home_outline"],
    "search": ["md-magnify"],
    "cloud-download": ["md-cloud_download_outline"],
    "user": ["md-account_outline"],
    "book": ["md-book_open_page_variant_outline", "md-book_outline"],
    "refresh": ["md-sync"],
    "library": ["md-bank_outline"],
    "star": ["md-star"],
    "star-half": ["md-star_half_full"],
    "tags": ["md-tag_multiple_outline", "md-tag_outline"],
    "date": ["md-calendar_outline", "md-calendar_blank_outline"],
    "cog": ["md-cog_outline"],
    "cogs": ["md-cog_multiple_outline", "md-cogs"],
    "plus": ["md-plus"],
    "heart": ["md-heart"],
    "angle-down": ["md-chevron_down"],
    "caret-down": ["md-menu_down"],
    "caret-left": ["md-menu_left"],
    "caret-right": ["md-menu_right"],
    "chevron-down": ["md-chevron_down"],
    "chevron-up": ["md-chevron_up"],
    "chevron-left": ["md-chevron_left"],
    "chevron-right": ["md-chevron_right"],
    "arrow-left": ["md-arrow_left"],
    "arrow-right": ["md-arrow_right"],
    "close": ["md-close"],
    "check": ["md-check"],
    "edit": ["md-pencil_outline"],
    "pencil": ["md-pencil_outline"],
    "trash": ["md-trash_can_outline"],
    "copy": ["md-content_copy"],
    "external-link": ["md-open_in_new"],
    "ellipsis-v": ["md-dots_vertical"],
    "random": ["md-shuffle_variant"],
    "sort-amount-asc": ["md-sort_ascending"],
    "sort-amount-desc": ["md-sort_descending"],
    "help": ["md-help_circle_outline"],
    "warning": ["md-alert_outline"],
    "send": ["md-send_outline"],
    "print": ["md-printer_outline"],
    "link": ["md-link_variant"],
    "bookmark": ["md-bookmark_outline"],
    "bug": ["md-bug_outline"],
    "image": ["md-image_outline"],
    "play": ["md-play"],
    "pause": ["md-pause"],
    "global-search": ["md-text_search", "md-database_search_outline"],
    "select-all": ["md-select_all"],
    "window-restore": ["md-window_restore"],
    "remove": ["md-minus"],
    "full-screen": ["md-fullscreen"],
    "hourglass": ["md-timer_sand"],
    "undo": ["md-undo"],
    "redo": ["md-redo"],
}


def outline(font, glyphs, names):
    """Return the name, the path data and the bounds of the first glyph found."""
    for name in names:
        if name in glyphs:
            pen = SVGPathPen(glyphs, ntos=lambda v: str(round(v)))
            glyphs[name].draw(pen)
            bounds = BoundsPen(glyphs)
            glyphs[name].draw(bounds)
            return name, pen.getCommands(), bounds.bounds
    return None, None, None


def image(path, bounds):
    """Return a square SVG image of a glyph, as a CSS url().

    The font's y axis points up, so the path is flipped, and the view box
    is the square around the glyph's bounds, so that it fills the mask.
    """
    x0, y0, x1, y1 = bounds
    side = max(x1 - x0, y1 - y0)
    x = x0 - (side - (x1 - x0)) / 2
    y = -y1 - (side - (y1 - y0)) / 2
    svg = (f"<svg xmlns='http://www.w3.org/2000/svg' "
           f"viewBox='{x:g} {y:g} {side:g} {side:g}'>"
           f"<path transform='scale(1 -1)' d='{path}'/></svg>")
    for char, code in (("<", "%3C"), (">", "%3E"), ("#", "%23")):
        svg = svg.replace(char, code)
    return f'url("data:image/svg+xml,{svg}")'


def rules(font):
    """Return the CSS of all the icons, and the icons without a glyph."""
    glyphs = font.getGlyphSet()
    selectors, per_icon, missing = [], [], []
    for icon, names in ICONS.items():
        name, path, bounds = outline(font, glyphs, names)
        if name is None:
            missing.append(icon)
            continue
        selector = f'svg:has(> use[*|href="#icon-{icon}"])'
        selectors.append(selector)
        url = image(path, bounds)
        per_icon.append(
            f"    /* {icon}: {name} */\n"
            f"    {selector} {{\n"
            f"        -webkit-mask-image: {url};\n"
            f"        mask-image: {url};\n"
            f"    }}\n")
    group = ",\n".join(f"    {s}" for s in selectors)
    common = (
        f"{group} {{\n"
        "        background-color: currentColor !important;\n"
        "        -webkit-mask-repeat: no-repeat;\n"
        "        mask-repeat: no-repeat;\n"
        "        -webkit-mask-position: center;\n"
        "        mask-position: center;\n"
        "        -webkit-mask-size: contain;\n"
        "        mask-size: contain;\n"
        "    }\n"
        f"{group.replace(',', ' > use,')} > use {{\n"
        "        display: none !important;\n"
        "    }\n")
    return common + "\n" + "\n".join(per_icon), missing


def main():
    font = TTFont(sys.argv[1] if len(sys.argv) > 1 else FONT)
    css, missing = rules(font)
    text = CSS.read_text()
    head, rest = text.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    CSS.write_text(head + BEGIN + "\n" + css + END + tail)
    print(f"{len(ICONS) - len(missing)} icons written to {CSS.name}")
    if missing:
        print("no glyph found for:", ", ".join(missing))


if __name__ == "__main__":
    main()
