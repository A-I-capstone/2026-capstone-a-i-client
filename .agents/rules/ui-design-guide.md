---
trigger: always_on
---

# UI/UX Design System & System Prompts for Flutter Agent

## 1. Design Philosophy & Core Aesthetics
*   **Playful & Friendly:** The interface must feel alive, welcoming, and expressive. Avoid rigid corporate layouts.
*   **Organic Shapes:** Use fluid, non-symmetric, and continuous curves instead of perfect geometric circles or standard rounded rectangles.
*   **Pastel Bold Palette:** Combine soft, desaturated pastel bases with a strict color budget: **one dominant color, one punchy accent, and one clean neutral**. Avoid blinding neon-on-dark overkill unless explicitly requested.
*   **Flat, Simple, Modern:** Maintain a clean look by avoiding heavy skeuomorphic 3D gradients or complex realism. Focus on solid shapes, clear typography, and minimal line work.

---

## 2. Rich & Active Animations
*   **Micro-interactions:** Every single user interaction (taps, hovers, focus changes) must trigger a snappy, bouncy micro-animation using `AnimatedContainer`, `TweenAnimationBuilder`, or `implicit animations`.
*   **Motion Curves:** Strictly avoid linear transitions. Always apply organic, elastic, or bouncy animation curves (e.g., `Curves.elasticOut`, `Curves.backInOut`).
*   **Idle Transitions:** Core AI components or conversational bubbles should have subtle, continuous idle animations (like floating or gentle pulsing) using `AnimationController` to look organic and alive.

---

## 3. Strict Anti-Patterns (How to Avoid "Vibe-Coded" Clichés)
To ensure the interface looks professionally engineered and deeply intentional, the Flutter Agent **MUST STRICTLY AVOID** the following generic AI-generated design traps:

### A. No Meaningless Glows & Aurora Backgrounds
*   **Critique:** Do not use radial gradients, light blooms, or glowing text as pure decoration behind dark mode interfaces.
*   **Rule:** Earn depth in dark mode through clean typography, crisp contrast, and thoughtful surface elevation layers (e.g., subtle brightness shifts in background colors), not through arbitrary glowing effects.

### B. No Systematic Emoji Abuse
*   **Critique:** Do not use emojis as a lazy shortcut for navigation icons, bullet points, or section headers. 
*   **Rule:** Use a cohesive, structured icon set (like `Icons` or `CupertinoIcons`) with consistent visual weight and sizing. Emojis should only be reserved for conversational microcopy where tone and human personality matter.

### C. No Auto-Pilot Purple Gradients
*   **Critique:** Do not default to purple-to-indigo or pink-to-blue gradients for every primary button, hero section, or splash component.
*   **Rule:** Choose color tokens based entirely on the specific product identity and context, not the statistical average of 2022 SaaS landing pages.

### D. No Nested "Card-in-Card" Cabinet Layouts
*   **Critique:** Do not wrap every single block of information inside a border or card component, creating endless nested boxes.
*   **Rule:** Group content using **whitespace, proximity, and typographic hierarchy** first. Reserve `Card` or bounded containers exclusively for objects that are independently actionable or interactive.

### E. No Rainbow Side Tabs & Fake Highlights
*   **Critique:** Do not add colored vertical accent bars to the side of every list item or card using alternating random colors.
*   **Rule:** Treat color as a shared, scarce resource across the entire page. Emphasis only works when 90% of the screen is suppressed. 

### F. No Decorative "Status Dots" 
*   **Critique:** Do not place small colored circles (green, red, orange) next to titles or labels unless they map to a live, actionable system state.
*   **Rule:** If a dot doesn't represent real-time data, remove it entirely or replace it with a clear text label. Decoration pretending to be data hurts usability.