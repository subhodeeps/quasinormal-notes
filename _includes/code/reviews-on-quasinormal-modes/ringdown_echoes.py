#!/usr/bin/env python3
#
# Author(s): Subhodeep Sarkar
# Affiliation: IIT Gandhinagar and IIIT Allahabad
# Contact: subhodeep.sarkar1@gmail.com
# Date: October 2026
#
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "numpy",
#     "matplotlib",
#     "amore @ git+https://github.com/subhodeeps/amore.mplstyle",
# ]
# ///

"""Plot the ringdown of a black hole and of a horizonless compact object.

The data file eco_ringdown_l2.npz comes from a frequency-domain
Green-function code that the author wrote during the PhD, based on Z.
Mark, A. Zimmerman, S. M. Du and Y. Chen, "A recipe for echoes from
exotic compact objects", arXiv:1706.06155. It holds the l = 2 waveform
Psi(r = 50 M, t) of a Schwarzschild black hole and of a compact object
whose perfectly reflecting surface sits at r = r_h (1 + 1e-11), for the
same initial pulse, in the arrays `h_time_BH` and `h_time_ECO` on the
times `t_grid` (in units of M). The two waveforms agree during the
prompt ringdown, and the compact object adds the echoes later on. The
figure follows Fig. 9 of V. Cardoso and P. Pani, Living Rev. Relativ.
22, 4 (2019), arXiv:1904.05363.

The script saves the figure twice, as ringdown-echoes-light.png and
ringdown-echoes-dark.png, for the light and dark themes of the site. It
is the figure of the post "Reviews on Quasinormal Modes". The amore
matplotlib stylesheet (https://github.com/subhodeeps/amore.mplstyle) is
optional: without it, the figure uses the default matplotlib style with
the same colours. amore typesets text with LaTeX; set USETEX = False
below if LaTeX is not installed.

Usage
-----
    uv run ringdown_echoes.py [folder]

The script reads eco_ringdown_l2.npz from its own folder and saves the
figures in ./figures, or in `folder` if given.
"""

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np

try:
    import amore
except ImportError:
    amore = None


# --- Data -------------------------------------------------------------

DATA = Path(__file__).with_name("eco_ringdown_l2.npz")

PROMPT_END = 140.0  # end of the prompt ringdown, in units of M
INSET_WINDOW = (150.0, 600.0)  # times of the inset, in units of M


def load(path=DATA):
    """Read the two waveforms.

    Parameters
    ----------
    path : pathlib.Path, optional
        The .npz file of the code of the repository.

    Returns
    -------
    t, bh, eco : ndarray
        Times in units of M, and the waveforms of the black hole and
        of the compact object at r = 50 M.
    """
    with np.load(path) as data:
        return data["t_grid"], data["h_time_BH"], data["h_time_ECO"]


# --- Aesthetics -------------------------------------------------------

USETEX = True

if amore is not None:
    BLUE, PLUM, SLATE = (
        amore.palette("blue"),
        amore.palette("plum"),
        amore.palette("slate"),
    )
else:
    # The same colours as the amore palettes
    BLUE = dict(ink="#2e1a6e", main="#5c9dc7", light="#b4d0e6", shade="#f4f4fa")
    PLUM = dict(light="#d6bfdc")
    SLATE = dict(ink="#28313d", light="#c2c9d1")

THEMES = {
    "light": dict(
        text=SLATE["ink"],
        bh=BLUE["ink"],
        eco=BLUE["main"],
        prompt=BLUE["shade"],
        prompt_alpha=1.0,
        grid=SLATE["ink"],
    ),
    "dark": dict(
        text=SLATE["light"],
        bh=PLUM["light"],
        eco=BLUE["main"],
        prompt=BLUE["main"],
        prompt_alpha=0.14,
        grid=SLATE["light"],
    ),
}

LOOK = dict(
    size=(6.0, 4.0),  # figure size in inches
    dpi=300,
    line_width=1.2,
    inset_width=0.8,
    spine_width=1.5,
    inset=[0.48, 0.52, 0.48, 0.43],  # left, bottom, width, height of the inset
)


def use_theme(theme):
    """Set the style and colours for one theme of the site.

    Uses amore if it is installed and the default matplotlib style
    otherwise, with a transparent background in both cases.

    Parameters
    ----------
    theme : {"light", "dark"}
        Theme of the site.

    Returns
    -------
    dict
        Colours of the theme, from `THEMES`.
    """
    if amore is not None:
        amore.use()
    else:
        plt.style.use("default")
    colours = THEMES[theme]
    plt.rcParams.update(
        {
            "text.usetex": USETEX,
            "mathtext.fontset": "cm",  # used when USETEX is False
            "text.color": colours["text"],
            "axes.labelcolor": colours["text"],
            "axes.edgecolor": colours["text"],
            "xtick.color": colours["text"],
            "ytick.color": colours["text"],
            "axes.facecolor": "none",
            "figure.facecolor": "none",
            "savefig.transparent": True,
            "axes.grid": False,
        }
    )
    return colours


# --- Drawing ----------------------------------------------------------


def style_axes(ax, colours):
    """Give the axes a dotted grid and frame of the theme.

    Parameters
    ----------
    ax : matplotlib.axes.Axes
    colours : dict
        Colours of the theme, from `THEMES`.
    """
    ax.grid(True, linestyle=":", linewidth=0.5, color=colours["grid"], alpha=0.5)
    for spine in ax.spines.values():
        spine.set_linewidth(LOOK["spine_width"])
        spine.set_color(colours["text"])


def figure_ringdown(data, colours):
    """Draw the waveforms of the black hole and the compact object.

    The prompt ringdown is shaded, and an inset shows the echoes of the
    compact object on a smaller scale.

    Parameters
    ----------
    data : tuple of ndarray
        Times and waveforms, as returned by `load`.
    colours : dict
        Colours of the theme, from `THEMES`.

    Returns
    -------
    matplotlib.figure.Figure
    """
    t, bh, eco = data
    fig, ax = plt.subplots(figsize=LOOK["size"], layout="constrained")
    ax.axvspan(
        0,
        PROMPT_END,
        facecolor=colours["prompt"],
        alpha=colours["prompt_alpha"],
        linewidth=0,
        zorder=0,
    )
    ax.plot(t, bh, "--", color=colours["bh"], lw=LOOK["line_width"], label="BH", zorder=3)
    ax.plot(t, eco, "-", color=colours["eco"], lw=LOOK["line_width"], label="ECO", zorder=2)
    ax.text(
        PROMPT_END - 15,
        1.0,
        r"\texttt{prompt ringdown}" if USETEX else "prompt ringdown",
        rotation=90,
        va="center",
        ha="right",
        fontsize=9,
    )
    ax.set_xlim(0, 600)
    ax.set_xlabel(r"$t/M$")
    ax.set_ylabel(r"$\Psi(r=50M,\,t)$")
    ax.legend(loc="lower right", frameon=False, fontsize=10, bbox_to_anchor=(0.98, 0.08))
    style_axes(ax, colours)

    inset = ax.inset_axes(LOOK["inset"])
    inset.plot(t, eco, color=colours["eco"], lw=LOOK["inset_width"])
    inset.set_xlim(*INSET_WINDOW)
    inset.set_ylim(-0.25, 0.25)
    inset.tick_params(axis="both", which="major", labelsize=8)
    style_axes(inset, colours)
    return fig


def main(out=Path("figures")):
    """Read the data, then save the figure in both themes.

    Parameters
    ----------
    out : pathlib.Path, optional
        Folder for the figures.
    """
    data = load()
    out.mkdir(parents=True, exist_ok=True)
    for theme in THEMES:
        colours = use_theme(theme)
        fig = figure_ringdown(data, colours)
        path = out / f"ringdown-echoes-{theme}.png"
        fig.savefig(path, dpi=LOOK["dpi"])
        plt.close(fig)
        print(path)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path("figures"))
