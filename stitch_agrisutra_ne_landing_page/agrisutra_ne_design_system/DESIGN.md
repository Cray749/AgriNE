---
name: AgriSutra NE Design System
colors:
  surface: '#ebffe6'
  surface-dim: '#c9e1c4'
  surface-bright: '#ebffe6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e2fadd'
  surface-container: '#ddf5d7'
  surface-container-high: '#d7efd2'
  surface-container-highest: '#d1e9cc'
  on-surface: '#0d200e'
  on-surface-variant: '#40493d'
  inverse-surface: '#223521'
  inverse-on-surface: '#dff7da'
  outline: '#707a6c'
  outline-variant: '#bfcaba'
  surface-tint: '#1b6d24'
  primary: '#0d631b'
  on-primary: '#ffffff'
  primary-container: '#2e7d32'
  on-primary-container: '#cbffc2'
  inverse-primary: '#88d982'
  secondary: '#006c45'
  on-secondary: '#ffffff'
  secondary-container: '#72f8b5'
  on-secondary-container: '#007149'
  tertiary: '#00598f'
  on-tertiary: '#ffffff'
  tertiary-container: '#0072b6'
  on-tertiary-container: '#e9f2ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a3f69c'
  primary-fixed-dim: '#88d982'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005312'
  secondary-fixed: '#75fbb8'
  secondary-fixed-dim: '#55de9e'
  on-secondary-fixed: '#002112'
  on-secondary-fixed-variant: '#005233'
  tertiary-fixed: '#cfe5ff'
  tertiary-fixed-dim: '#99cbff'
  on-tertiary-fixed: '#001d34'
  on-tertiary-fixed-variant: '#004a78'
  background: '#ebffe6'
  on-background: '#0d200e'
  surface-variant: '#d1e9cc'
typography:
  display-lg:
    fontFamily: Outfit
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 48px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system embodies "Eco-Minimalism"—a fusion of high-tech precision and organic rootedness. It is designed to feel like a premium laboratory tool that has been brought into the field, blending the clinical clarity of modern SaaS with the lush, vibrant energy of Northeast India’s agricultural landscape.

The target audience ranges from tech-savvy young farmers to government agricultural officers. The UI must evoke **Trust, Precision, and Vitality**. We achieve this through a "Light & Airy" aesthetic: heavy use of whitespace to reduce cognitive load, combined with subtle glassmorphism to represent the "AI layer" sitting atop traditional farming wisdom. The visual language is sophisticated yet accessible, prioritizing legibility and data visualization.

## Colors
The palette is anchored in **Forest Green**, representing stability and growth. The **Mint Accent** acts as our primary interactive signal, drawing the eye to calls-to-action and AI-generated insights.

A unique secondary palette is reserved for the NPK (Nitrogen, Phosphorus, Potassium) triad, ensuring that complex fertilizer prescriptions are immediately scannable through color-coding. Surfaces use a nearly-white "Milk-Wash" green (#FAFEFA) to prevent the harshness of pure white while maintaining a clean, modern atmosphere.

## Typography
Typography is split into three functional roles:
1.  **Outfit** (Headlines): Used for structural hierarchy. Its geometric, open characters provide a modern, optimistic feel.
2.  **Inter** (Body): The workhorse for all instructional and descriptive text. Chosen for its exceptional legibility at small sizes.
3.  **JetBrains Mono** (Data): Reserved specifically for fertilizer quantities, soil pH levels, and coordinate data. The monospaced nature emphasizes "Science" and technical accuracy.

For mobile, headline sizes are slightly reduced to ensure no awkward wrapping of scientific terms.

## Layout & Spacing
This design system utilizes a **12-column fixed grid** for desktop and a **4-column fluid grid** for mobile. The spacing rhythm is strictly based on 8px increments.

Generous whitespace is mandatory to maintain the "Apple-esque" premium feel. Sections should be separated by large vertical stacks (`stack-lg`) to give the content room to breathe. On mobile, margins tighten to 16px to maximize screen real estate for data tables, but vertical padding remains high to prevent a "cramped" feeling.

## Elevation & Depth
The system uses **Tonal Layering** combined with **Glassmorphism**. 

- **Level 0 (Background):** #FAFEFA.
- **Level 1 (Cards/Containers):** #FFFFFF with a subtle 1px border (#E8F0E8).
- **Level 2 (Modals/Overlays):** Semi-transparent white (#FFFFFFCC) with a 20px backdrop blur. This represents the "AI processing" layer.

Shadows are virtually non-existent; instead, depth is created through high-contrast borders and subtle background color shifts. When a shadow is necessary (e.g., a floating action button), it is highly diffused, using the primary green tint (#2E7D3215) instead of pure black.

## Shapes
The shape language is "Organic Geometric." 

- **Cards & Primary Containers:** 16px (`rounded-lg`) to feel approachable and modern.
- **Buttons & Inputs:** 12px (defined as a subset of `rounded-lg`) for a more focused, tactile feel.
- **Badges/Chips:** Fully pill-shaped to contrast against the structured cards.

All icons should follow a "Light" weight (1.5pt stroke) with rounded terminals to match the typography of Outfit.

## Components
- **Buttons:** Primary buttons use a solid Mint (#69F0AE) with dark text (#1B2E1B) for maximum contrast. Secondary buttons use a Forest Green outline. Hover states should include a subtle upward shift (-2px) to feel "airy."
- **Cards:** White base, 16px corner radius, 1px soft border. AI-driven cards (like prescriptions) feature a top-border accent in the Nitrogen, Phosphorus, or Potassium specialty color.
- **Inputs:** Minimalist style. Underline or light grey background with a 12px radius. The focus state uses a 2px Mint border.
- **NPK Data Chips:** Small, high-contrast labels using JetBrains Mono. 
    - N: Mint Background
    - P: Blue Background
    - K: Orange Background
- **Glass Prescriptions:** A special component for AI summaries using a backdrop-blur background, positioned at the top of results to signify it is an overlay of "Intelligence" on top of raw data.
- **Micro-animations:** Loading states for AI prescriptions should use a "pulse" that mimics organic growth or cellular division.