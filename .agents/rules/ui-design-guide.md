---
trigger: always_on
---

# Design system rules — wellness app for kids (ages 8–12)

Governs every screen, component, and asset generated. On conflict, follow this file and
say so — don't silently override it.

## Audience & tone

User is 8–12. Big, bold, friendly, legible beats clever, dense, or subtle. Visual target:
organic, wavy, asymmetric — nothing snapped to a rigid grid. Hand-cut paper shapes
overlapping at playful angles, not aligned boxes.

Two layers:
1. **Illustrated layer** (primary — color, shape, buttons, mascots): bold citrus palette,
   organic/wavy/asymmetric shapes, flat solid fills, thick ink outlines instead of
   shadows, single-color blob mascots with minimal line faces, big circular ink-black
   buttons, full-bleed sunrise gradients with wavy (not straight) horizon edges.
2. **Structural layer** (secondary — layout/IA only, not color): simple app shell — bottom
   tab bar, dashboard home, single-column library feed, segmented profile tabs. Let the
   illustrated layer's organic shapes and asymmetric placement break this grid wherever
   possible.

"Bold" and "playful" are not exceptions to the Anti-vibe-coding checklist at the end —
that checklist is equally binding. See the color-budget note for how the two coexist.

## MUST

- Use only tokens defined below. No new brand hues, radii, or fonts.
- Primary buttons: solid ink-black (`#3A3936`) circle (icon-only) or pill (labeled, e.g.
  "Begin"). Never outline-only, never gradient-filled.
- Touch targets are large: primary buttons ≥56px tall, full/near-full width on mobile;
  icon buttons ≥48x48px with ≥12px clear space around them.
- Type is large: body ≥18px (never <16px anywhere), headlines ≥28px, hero/display ≥36px.
- Text/CTA contrast ≥4.5:1, prefer 7:1+ where the palette allows.
- Mascot/blob illustration only for empty states, content cards, social/share moments —
  never generic decorative fill or icon replacement.
- Compose asymmetrically: offset hero illustrations, let shapes bleed off-canvas, vary
  card sizes within a row, give at least one element per screen a slight (few-degree)
  rotation.
- Use wavy/organic edges wherever two color fields meet: section breaks, card bottoms,
  gradient horizon lines — never a straight or perfectly circular edge there.
- Section eyebrows: uppercase, tracked-out, muted-grey labels ("MY COURSES"), sized per
  the type floors above.
- Player/content-detail: full-bleed vertical sunrise gradient with wavy horizon edge,
  one large centered circular play/pause control, minimal scrubber, close (X) top-right.
- Bottom tab bar: 3 items (Home / Library / Profile), icon + label. Keep this strictly
  grid-aligned even while content above stays organic/asymmetric — kids need one
  predictable anchor.

## NEVER

- Never mix flat-outline elevation (illustrated layer) with soft-shadow elevation
  (structural layer) on the same screen.
- Never give a mascot shape more than one color or a gradient.
- Never use photographic imagery inside a meditation/content surface (photos only on
  profile/social-share screens).
- Never use serif, script, or condensed type.
- Never place two primary-palette accents edge-to-edge without an ink/neutral separator,
  unless deliberately reproducing the sunrise gradient.
- Never add a dark mode — none is defined; flag as undefined if asked.
- Never shrink type or touch targets below the stated floors to fit more content — cut
  content instead.
- Never use a straight/geometric edge where an organic wave or blob edge is called for.

## Color tokens

```css
:root {
  /* Primary — brand chrome, buttons, content surfaces */
  --color-sunrise-yellow: #FFE772;
  --color-marigold:       #FFC533;
  --color-tangerine:      #FF9849;
  --color-saffron:        #FECE01;
  --color-ocean:          #0440FE;
  --color-ocean-soft:     #2672F1;
  --color-sand:           #9B6C53;
  --color-ink:            #3A3936;

  /* Neutrals */
  --color-bg:             #F8F4F2;
  --color-surface:        #FFFFFE;
  --color-border:         #ADAAA4;

  /* Secondary — shell surfaces, category rotation, bold accent moments only */
  --color-slate:          #667595;   /* icons/large text only, 4.62:1 on white */
  --color-clay:           #EC8D42;
  --color-peach:          #FADFA5;
  --color-periwinkle:     #7B8BBD;
  --color-mint:           #8BE5B5;
  --color-teal-cta:       #5AC1BC;
}
```

Bold ≠ unlimited: use large fields of full-strength primary color, not more colors.
Budget per screen: one dominant hue, one accent, one neutral. One secondary-ramp color may
appear as a bold accent moment, but never a second one alongside it — three-plus
saturated hues on one screen is the neon-chaos pattern the checklist forbids.

## Shape & composition

- Shape scale (4 steps): `pill` (999px, buttons/chips) · `card` (~24px) · `blob`
  (free-form silhouette — mascots, hero shapes, card backgrounds) · `wave` (hand-drawn
  horizontal curve at any color-field boundary). Straight rectangles reserved for the tab
  bar and small chrome only.
- Asymmetry is a rule: vary card widths in a row, offset hero illustrations, let blobs
  bleed past container edges. Only the tab bar and data-entry forms stay grid-aligned.
- Elevation, illustrated layer: flat fill + 2px ink outline, no shadow.
- Elevation, shell surfaces: soft low-opacity shadow, no outline. Confine to shell chrome.
- Icons: minimal, thick rounded stroke or solid, ≥24px, inside solid ink-black circular
  targets. No emoji — see checklist.
- Mascots/hero blobs may tilt slightly or overlap their container edge (subtle, a few
  degrees) — this is the main source of the hand-placed, asymmetric feel.

## Typography

- Rounded geometric sans-serif throughout (Nunito, General Sans, or rounded system font).
  No serif, condensed, or script.
- Floors: body/caption 18px, section labels 16px, headline 28px+, hero 36px+. Line
  height 1.4–1.6 for body.
- Weights: 700+ headlines/CTAs, 500–600 body/captions (never lighter), 600 + uppercase +
  ~0.08em tracking for eyebrows.
- Voice: short, second-person, imperative, encouraging ("Kick the Panic"). Simple
  vocabulary for an 8–12 reading level. CTAs are friendly concrete verbs ("Begin,"
  "Let's go") — never generic ("Submit") or clinical.

## Mascot / illustration system

- Amorphous, non-representational blob/polygon silhouettes, one flat color each, no
  gradient or texture.
- Faces: two curved-line eyes + one curved-line mouth, thin ink stroke. No pupils, no
  other features.
- Two shapes may overlap/"hold" each other for social features; each keeps a single flat
  fill.

## App-shell patterns

- **Home**: wavy-edged gradient hero ("Day X of Y," one large offset CTA pill) →
  horizontal scroll rows under eyebrow labels, varied card widths → 2-up grid with
  slightly varied card heights.
- **Library**: filter dropdown + one intro line → single-column blob/wave-edged feature
  cards with category chip + duration tag.
- **Profile**: avatar + name + gear → segmented tabs (Stats/Journey) → one full-bleed
  wavy-edged accent panel with one large CTA → list rows.
- **Mood check-in**: full-screen sequence of solo mascot cards, one word each, forming a
  sentence on swipe. Reserved for mood/reflection prompts only.

## Anti-vibe-coding checklist

Check every screen against these before calling it done. Bold/playful for a young
audience changes scale and confidence, not discipline.

1. **No competing-neon palettes.** One dominant, one accent, one neutral, full-saturation,
   large scale. 3+ saturated hues at once = delete down to budget.
2. **No decorative glow/blur/aurora.** No radial gradients or bloom "for atmosphere." No
   dark mode, no glow language. The brand's blobs are flat, solid, hand-cut shapes — a
   blurred/glowing "aura" around a shape is the forbidden pattern, not the wave language.
3. **No emoji as UI elements.** Never for nav, headers, bullets, decoration. Only the
   defined icon system. Emoji OK only inside user-typed microcopy.
4. **No purple/indigo "tech" gradients.** Only gradient is the sunrise ramp, on
   player/hero surfaces with a wavy edge. Never a generic purple-blue "modern" gradient.
5. **No box-in-a-box nesting.** Cap cards at one level. Group other content with
   whitespace/proximity/type instead of another container.
6. **No rainbow-cycling side accent bars.** No colored left-border on every card cycling
   hues with no logic. Accent color = one defined signal (active/selected), not decoration.
7. **No meaningless status dots.** A dot only if it maps to a documented state, with that
   mapping visible (legend/label/adjacent word). For this audience, prefer a
   plain-language label over a dot in almost every case.

If 2+ patterns appear on a screen, stop and simplify before shipping.