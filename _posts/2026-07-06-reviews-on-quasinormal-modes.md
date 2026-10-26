---
title: Reviews on Quasinormal Modes
short_title: "QNM Reviews" # in the note graph
description: "We list review articles, lecture notes, book chapters and books on quasinormal modes and black hole perturbation theory."
date: 2026-07-06 00:00:00 +0530
categories: [Physics, Black Holes, Quasinormal Modes]
also_in: [Physics, Physics Resources]
tags: [black-holes, quasinormal-modes, reviews, general-relativity, gravitational-waves, differential-equations, black-hole-perturbations]
pin: true
last_modified_at: 2026-10-26 00:00:00 +0530
math: true
---

> "Over twenty years ago Regge & Wheeler (1957) pioneered in the use of perturbation methods to study black hole dynamics. I find it remarkable that after all of this time the subject is still yielding interesting information and has ample opportunities for research projects."
> 
> — S. L. Detweiler, 1978 {: .text-right }

![Ringdown waveform of a black hole compared with that of a horizonless compact object](/assets/images/reviews-on-quasinormal-modes/ringdown-echoes-light.png){: .light width="1800" height="1200" }
![Ringdown waveform of a black hole compared with that of a horizonless compact object](/assets/images/reviews-on-quasinormal-modes/ringdown-echoes-dark.png){: .dark width="1800" height="1200" }

<span class="aps-label">Fig. 1.</span> Ringdown waveform of a black hole (dashed) compared with that of a horizonless compact object (solid), from our own simulation after Fig. 9 of [V. Cardoso and P. Pani](#Cardoso:2019rvt), [*Living Rev. Rel.* **22** (2019) 4](https://doi.org/10.1007/s41114-019-0020-4).
{: .aps-caption .aps-figure}

While writing my thesis I gathered all the reviews on quasinormal modes that I know of in one [`bib` file](https://gist.github.com/subhodeeps/e6cb99d86ec2ccea78bb51e4f7fb6d87), along with some lecture notes and the book chapters. They differ wildly in their style, motivation and pedagogy, but they are all pretty fun to read, and I hope that at least one of them proves useful to you, or perhaps tempts you to explore this subject (even) further! For lecture notes on black holes and general relativity in general, see [[2026-07-06-lecture-notes]].

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
