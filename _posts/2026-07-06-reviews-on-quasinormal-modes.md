---
title: Reviews on Quasinormal Modes
short_title: "QNM Reviews" # in the note graph
description: "We list review articles, lecture notes, book chapters and books on quasinormal modes and black hole perturbation theory."
date: 2026-07-06 00:00:00 +0530
categories: [Physics, Black Holes, Quasinormal Modes]
also_in: [Physics, Physics Resources]
tags:
  [
    black-holes,
    quasinormal-modes,
    reviews,
    general-relativity,
    gravitational-waves,
    differential-equations,
    black-hole-perturbations,
  ]
pin: true
last_modified_at: 2026-10-26 00:00:00 +0530
math: true
---

> "Over twenty years ago Regge & Wheeler (1957) pioneered in the use of perturbation methods to study black hole dynamics. I find it remarkable that after all of this time the subject is still yielding interesting information and has ample opportunities for research projects."
>
> — S. L. Detweiler, 1978
> {: style="text-align: right" }

When a black hole is formed due to gravitational collapse, it remains in a perturbed state for a short time. As the black hole settles down into its final state, described by the Kerr solution in general relativity, it emits gravitational waves. After an initial outburst, the emitted gravitational waves decay. The decaying oscillations are called _quasinormal modes_ (QNMs) and describe the characteristic frequencies of the black hole. We can use linear perturbation theory to determine these quasinormal mode frequencies accurately. These quasinormal modes play an essential role in analyzing the stability of the black hole spacetime and govern the status of several fundamental questions in spacetime physics. In gravitational wave astronomy, QNMs also model the prompt ringdown phase that follows the inspiral and merger phases during binary black hole coalescence, and can be used to estimate the mass and spin of the remnant black hole.

In [Fig. 1](#fig-1), we show the result of a numerical computation of the ringdown signal of a black hole and of a horizonless compact object. Right after the merger, we see that the prompt ringdown phase is practically identical, but the absence of a horizon gives rise to a train of late-time echoes.

![Ringdown waveform of a black hole compared with that of a horizonless compact object](/assets/images/reviews-on-quasinormal-modes/ringdown-echoes-light.png){: .light width="700" height="467" }
![Ringdown waveform of a black hole compared with that of a horizonless compact object](/assets/images/reviews-on-quasinormal-modes/ringdown-echoes-dark.png){: .dark width="700" height="467" }

<span class="aps-label">Fig. 1.</span> Ringdown waveform of a black hole (dashed) compared with that of a horizonless compact object (solid), from our own simulation after Fig. 9 of [V. Cardoso and P. Pani](#Cardoso:2019rvt), [_Living Rev. Rel._ **22** (2019) 4](https://doi.org/10.1007/s41114-019-0020-4).
{: #fig-1 .aps-caption .aps-figure}

The study of linear perturbations to black hole spacetimes has been a remarkably prolific area of research, starting with the groundbreaking work of Regge and Wheeler (and Zerilli, Vishveshwara, Press, Teukolsky, Leaver, Moncrief, Chandrasekhar and Detweiler, and $\ldots$), and it continues to grow practically daily even today. While writing my thesis I gathered all the reviews on quasinormal modes that I know of in one modest [`bib` file](https://gist.github.com/subhodeeps/e6cb99d86ec2ccea78bb51e4f7fb6d87), along with some lecture notes, books and book chapters. They differ wildly in their style, motivation and pedagogy, but (except for Chandrasekhar's magnum opus) they are all pretty fun to read. I hope that at least a few of them will be interesting to you, or perhaps tempt you to explore this subject (even) further! For lecture notes on black holes and general relativity, see [[2026-07-06-lecture-notes]].

<details class="prompt-fold prompt-review" open markdown="1">
<summary markdown="span">I would recommend the following resources as a starting point.</summary>

{% bibliography --template bib-box --query @*[keywords ~= qnm-start] %}

</details>

## Reviews

{% bibliography --query @*[keywords ~= qnm-reviews] %}

## Lecture notes

{% bibliography --query @*[keywords ~= qnm-notes] %}

## Book chapters

{% bibliography --query @*[keywords ~= qnm-chapters] %}

## Books

{% bibliography --query @*[keywords ~= qnm-books] %}
