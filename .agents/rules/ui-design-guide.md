---
trigger: always_on
---

# Design system rules

This file governs every screen, component, and asset the agent generates. If a request
conflicts with a rule below, follow this file and say so — do not silently override it.

The brand has two layers. Read both before generating anything:

1. **Illustrated brand layer** (primary — governs color, shape, buttons, mascots): a warm,
   citrus-toned visual language. Flat solid colors, thick ink outlines instead of shadows,
   amorphous single-color "blob" mascot characters with minimal line faces, big circular
   ink-black buttons, full-bleed sunrise-gradient backgrounds on content/player screens.
2. **Structural/navigation layer** (secondary — governs layout and IA only, not color):
   a conventional app shell — bottom tab bar, dashboard home, single-column library feed,
   segmented profile tabs. Use this for screen structure. Its own color palette (softer,
   more pastel) is available only for background rotation on shell surfaces, never for
   primary buttons or brand chrome — see Color tokens below.

Every rule in this file exists to keep the interface looking like a specific, considered
brand — not like the statistical average of "modern SaaS UI." That average has a
recognizable look of its own (see the Anti-vibe-coding checklist at the end). Treat that
checklist as equally binding as the brand rules above it.

## MUST

- Use only the tokens defined below. Do not invent new brand hues, radii, or fonts.
- Primary buttons: solid ink-black (`#3A3936`) circle (icon-only, e.g. play/pause) or pill
  (labeled, e.g. "Begin," "Meditate"). Never outline-only, never gradient-filled.
- Every text/CTA pairing must hit ≥4.5:1 contrast. Ink-on-sunrise (yellow/gold/tangerine)
  and white-on-ink both clear this by default — verify anything else before shipping it.
- Mascot/blob illustration: reserve for empty states, content cards, and social/share
  moments. Never use it as a generic decorative fill or icon replacement.
- Section eyebrows use uppercase, tracked-out, small, muted-grey labels
  for every list/section header, app-wide.
- Player/content-detail screens: full-bleed vertical sunrise-gradient background, one large
  centered circular play/pause control, minimal scrubber, close (X) top-right.

## NEVER

- Never mix the flat-outline elevation of the illustrated layer with the soft-shadow
  elevation of the structural layer on the same screen. Pick one per surface type.
- Never fill a mascot shape with more than one color or a gradient — one flat hue per shape.
- Never use photographic imagery inside a meditation/content surface (photography is
  acceptable only on profile or social-share screens).
- Never use serif, script, or condensed type anywhere.
- Never place two primary-palette accents edge-to-edge without an ink or neutral separator,
  unless deliberately reproducing the sunrise gradient itself.

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
  --color-ink:            #3A3936;   /* text, icons, primary button fill */

  /* Neutrals — backgrounds and cards */
  --color-bg:             #F8F4F2;   /* warm off-white page background */
  --color-surface:        #FFFFFE;   /* card / sheet surface */
  --color-border:         #ADAAA4;   /* hairline on outlined cards */

  /* Secondary — shell surfaces and category rotation only, never brand chrome */
  --color-slate:          #667595;   /* icons/large text only, 4.62:1 on white */
  --color-clay:           #EC8D42;
  --color-peach:          #FADFA5;
  --color-periwinkle:     #7B8BBD;
  --color-mint:           #8BE5B5;
  --color-teal-cta:       #5AC1BC;
}
```

**Color budget, enforced everywhere:** one dominant (a primary sunrise hue), one accent
(ocean blue or ink), one neutral (cream/white). Content categories may rotate through the
secondary ramp for card/header backgrounds on shell surfaces, but primary actions, buttons,
and core brand chrome always stay in the primary set — never the secondary one, and never
more than the dominant/accent/neutral trio active on a single screen at once.

## Shape & elevation

- **Corner radius scale** (3 steps only): `pill` (999px, buttons/chips) · `card` (~24px,
  content cards, sheets) · `blob` (free-form organic silhouette, mascots only — never UI chrome).
- **Elevation, illustrated-layer surfaces**: flat fill + 2px ink-colored outline. No box-shadow.
- **Elevation, shell surfaces** (home/library/profile): soft, low-opacity drop shadow, no
  outline. Keep this confined to shell chrome, not content/player screens.
- **Iconography**: minimal, thick rounded stroke or solid glyphs, sitting inside solid
  ink-black circular touch targets (camera, play, pause, close). No emoji, ever — see
  the checklist below.

## Typography

- Rounded geometric sans-serif family throughout (e.g. a rounded grotesk — Nunito, General
  Sans, or platform-default rounded system font). No serif, no condensed, no script.
- Weight ladder: **700+** for headlines and CTA labels, **500** for body/captions,
  **600 + uppercase + ~0.08em tracking** for section eyebrows.
- Copy voice: short, second-person, imperative ("Kick the Panic," "Check in with your
  friends"). CTAs are concrete verbs ("Begin," "Meditate," "Subscribe Now") — never generic
  ("Submit," "Continue").
- Default body font size must be at least 18sp.

## Mascot / illustration system

- Characters are amorphous, non-representational blob/polygon silhouettes — one flat
  brand color each, no gradient, no texture.
- Faces are minimal: two curved-line eyes + one curved-line mouth in a thin ink stroke.
  No pupils, no other features, no realistic proportions.
- Two shapes may overlap or "hold" each other to signal connection/social features, but
  each individual shape still keeps a single flat fill.

## Children's app guideline
- Always set minimum touch targets for buttons to 52x52 dp.
- Add scale/bounce animations when buttons are pressed.
- Avoid standard `CircularProgressIndicator`; use fun pulsing/animated loading indicators.

## Anti-vibe-coding checklist

The agent must actively check its own output against these seven failure patterns before
considering any screen done. These are the visual tells of ungoverned AI-generated UI —
avoiding them is not optional polish, it is what makes this look like a designed product
instead of a statistical average.

1. **No competing-neon palettes.** The color budget above (one dominant, one accent, one
   neutral) is a hard cap. If a screen has five or six saturated hues shouting at the same
   volume, delete down to the budget before shipping.
2. **No decorative glow, blur, or aurora effects.** No radial gradients, glow, or bloom
   behind text or hero sections "for atmosphere." This brand has no dark mode and no glow
   language at all — see NEVER above. Any lighting effect must respond to a real
   interaction or state; otherwise remove it.
3. **No emoji as UI elements.** Never use emoji for navigation icons, section headers,
   bullets, or decoration. Use only the defined icon system: thick rounded stroke or solid
   ink glyphs. Emoji are acceptable only inside conversational microcopy the user typed,
   never as interface chrome the agent authors.
4. **No purple/indigo "tech" gradients.** This brand's only gradient is the sunrise ramp
   (yellow → gold → tangerine), used exclusively on player/hero surfaces. Never default to
   a purple-to-blue gradient as a generic "modern" or "innovative" signal — it isn't part
   of this system and shouldn't appear anywhere in it.
5. **No box-in-a-box nesting.** Cap card nesting at one level. A card inside a card inside
   a card is a defect, not a hierarchy. Cards are reserved for content that is independently
   actionable; group everything else with whitespace, proximity, and the type ladder
   instead of another container.
6. **No rainbow-cycling side accent bars.** Do not put a colored left-border strip on every
   card or list item, cycling through different hues with no logic. Accent color is a
   single, defined signal (active/selected state) — not a decorative default applied to
   every block.
7. **No status dots without a defined meaning.** A colored dot may appear only if it maps
   to a specific, documented state (e.g. online/offline, live/scheduled) and that mapping
   is visible somewhere in the UI (a legend, a label, an adjacent word). If a dot would
   need explaining and none is given, use a text label instead, or remove the dot.

Before finishing any screen, scan it against this list explicitly. If more than one of
these seven patterns is present, stop and simplify rather than shipping.