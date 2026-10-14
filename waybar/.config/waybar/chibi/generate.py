#!/usr/bin/env python3
"""Generate the original vector dance frames; no external assets required."""
from pathlib import Path
import math
root = Path(__file__).resolve().parent
for happy in (False, True):
    for frame in range(8):
        phase = frame * math.pi / 4
        bob = -abs(math.sin(phase)) * 2
        sway = math.sin(phase) * 2
        arm = math.sin(phase) * 5
        eyes = '<path d="M24 15q2-3 4 0m6 0q2-3 4 0" fill="none" stroke="#45375d" stroke-width="1.5"/>' if happy or frame == 6 else '<g fill="#6555aa"><ellipse cx="26" cy="15" rx="2" ry="3"/><ellipse cx="36" cy="15" rx="2" ry="3"/></g><g fill="white"><circle cx="26.5" cy="14" r=".8"/><circle cx="36.5" cy="14" r=".8"/></g>'
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="62" height="32" viewBox="0 0 62 32">
<ellipse cx="31" cy="30" rx="12" ry="1.2" fill="#cba6f7" opacity=".16"/>
<g transform="translate({sway} {bob})" stroke-linecap="round" stroke-linejoin="round">
<!-- twin tails, legs and dancing arms -->
<path d="M22 9Q13 6 17 {23+arm/3}L22 20ZM40 9Q49 6 45 {23-arm/3}L40 20Z" fill="#b49be5" stroke="#77609d" stroke-width=".7"/>
<path d="M28 26l{-2-sway} 3m8-3l{2-sway} 3" stroke="#eee4ff" stroke-width="2.5"/>
<path d="M26 22L20 {20+arm}M36 22L42 {20-arm}" stroke="#ffdccf" stroke-width="2.8"/>
<path d="M27 20h8l5 7q-9 3-18 0Z" fill="#cba6f7" stroke="#77609d" stroke-width=".7"/>
<path d="M27 21l4 4 4-4" fill="#faf2ff"/><path d="M29 23l2-1 2 1-2 2Z" fill="#f38ba8"/>
<ellipse cx="31" cy="12" rx="11" ry="10" fill="#cba6f7" stroke="#77609d" stroke-width=".8"/>
<ellipse cx="31" cy="14" rx="9" ry="7.5" fill="#ffdfd3"/>
<path d="M21 13Q19 2 30 2Q43 2 41 13L37 9l-1 3-6-6-2 6-3-3-2 4Z" fill="#cba6f7"/>
<path d="M22 6l-4-2v6l4-2m18-2 4-2v6l-4-2" fill="#f38ba8"/>
{eyes}
<g fill="#f4a4bb" opacity=".7"><ellipse cx="23.5" cy="18" rx="2" ry="1"/><ellipse cx="38.5" cy="18" rx="2" ry="1"/></g>
<path d="M29 18q2 2 4 0" fill="none" stroke="#a56780" stroke-width=".8"/>
</g>
<g fill="{'#f38ba8' if happy else '#f9e2af'}" opacity="{.5 + abs(math.sin(phase))*.5}">
{'<path d="M50 9c-6-5-7 3 0 6 7-3 6-11 0-6Z"/>' if happy else '<path d="M51 10l1.2 3.2 3.3 1-3.3 1L51 19l-1-3.8-3-1 3-1Z"/>'}
<circle cx="10" cy="{14+arm}" r="1.2"/>
</g></svg>'''
        (root / f'{"happy" if happy else "dance"}-{frame}.svg').write_text(svg)
