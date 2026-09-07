---
name: SMK Al-Madani Lab Inventory
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#454651'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4559aa'
  primary: '#1e3484'
  on-primary: '#ffffff'
  primary-container: '#384c9d'
  on-primary-container: '#b7c3ff'
  inverse-primary: '#b8c4ff'
  secondary: '#bb0119'
  on-secondary: '#ffffff'
  secondary-container: '#e0292e'
  on-secondary-container: '#fffbff'
  tertiary: '#715c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#cba800'
  on-tertiary-container: '#4d3e00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde1ff'
  primary-fixed-dim: '#b8c4ff'
  on-primary-fixed: '#001454'
  on-primary-fixed-variant: '#2b4091'
  secondary-fixed: '#ffdad6'
  secondary-fixed-dim: '#ffb3ad'
  on-secondary-fixed: '#410003'
  on-secondary-fixed-variant: '#930011'
  tertiary-fixed: '#ffe17b'
  tertiary-fixed-dim: '#ecc300'
  on-tertiary-fixed: '#231b00'
  on-tertiary-fixed-variant: '#554500'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.04em
  code-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 3rem
  margin-mobile: 1rem
  gutter-mobile: 0.75rem
  appbar-height: 4rem
  bottomnav-height: 5rem
---

## Brand & Style

This design system establishes a high-reliability, institutional utility interface tailored specifically for vocational school administrators, laboratory technicians (*Laboran / Staf TU*), and department heads (*Kepala Lab & Kaprog TKJ*). The operational setting demands an authoritative, clear, and highly scannable mobile-first environment optimized for high-throughput tasks: asset scanning, hardware diagnostics, consumable tracking, and formal sign-offs.

The aesthetic fuses Google Material Design 3 (Material You) structure with crisp modern institutional utility:
- **Tone:** Authoritative, structured, dependable, and efficient.
- **Physical Feel:** Tactile clarity through defined card surfaces, standard M3 touch targets (min 48dp), and deliberate tonal separation.
- **Visual Discipline:** Strong hierarchy where functional states (nominal, pending verification, critical stock, damaged) are instantly discernible under varying lighting conditions within technical workshops.

## Colors

The palette leverages high-contrast institutional tones rooted in academic governance, technical precision, and immediate action-readiness.

### Functional Roles
- **Primary (`#384C9D` - Deep Navy Blue):** Establishes institutional authority. Applied to top app bars, primary affirmative actions, active bottom navigation states, and primary audit/supervisory metric panels.
- **Secondary / Accent (`#D8232A` - Crimson Red):** High-priority trigger color reserved for urgent actions, Floating Action Buttons (FAB) for quick report generation, critical low-stock alerts, overdue returns, and destructive confirmation modals.
- **Tertiary / Warning (`#FCD116` - Vibrant Gold Yellow):** Applied to pending supervisory approvals, calibration warnings, maintenance flags, and secondary highlight chips. Paired with dark text (`#78350F` or `#1E293B`) to maintain WCAG AAA legibility.
- **Canvas / Background (`#F8FAFC` - Slate Canvas):** Cool-toned off-white that minimizes glare during prolonged physical scanning and inventory auditing.
- **Surface / Cards (`#FFFFFF` - Pure White):** Crisp, isolated operational planes framed by subtle borders and ambient shadows.
- **Text & Content Hierarchy:**
  - `Title / Primary Text`: Deep Slate (`#1E293B`)
  - `Body / Metadata`: Muted Slate (`#64748B`)
  - `Dividers / Outlines`: Light Slate (`#E2E8F0`)
  - `Surface Tint / Containers`: Subdued Navy Tint (`#EEF2FF`) and Alert Tint (`#FEF2F2`)

## Typography

The type system prioritizes data readability, immediate visual identification of serial numbers and asset codes, and unambiguous administrative statuses.

- **Typeface Selection:** Inter is implemented across all roles for its neutral, highly legible geometric structure, uniform numeral heights (tabular figure support), and exceptional small-screen rendering.
- **Data & Serial Identifiers:** Asset tags, MAC addresses, and barcode labels use `code-md` or `label-md` with tabular spacing and explicit tracking to prevent ambiguous digit scanning (e.g., distinguishing `0` vs `O` or `1` vs `l`).
- **Hierarchy Rules:**
  - View headers and major counts utilize `headline-lg` and `headline-md` in `#1E293B`.
  - Item labels, hardware titles, and card headers use `title-md`.
  - Secondary metadata (specifications, lab room tags, dates) uses `body-md` and `body-sm` in `#64748B`.
  - Badges and status pills leverage `label-sm` in uppercase tracking.

## Layout & Spacing

The layout model adheres to standard Material Design 3 mobile ergonomics, built around a responsive 4-column layout on compact screens (<600dp) and 8-column layout on medium/tablet devices (600dp–840dp).

- **Margins & Safe Zones:** Mobile viewport margins are locked to `1rem` (16dp). Dense lists use an internal padding of `0.75rem` (12dp) to maximize vertical throughput.
- **Touch Target Integrity:** All interactive elements (icon buttons, list tile triggers, checkboxes) adhere strictly to the 48×48dp minimum physical target area, regardless of visible graphical size.
- **Vertical Rhythm:** 
  - Section headers maintain `1.5rem` (24dp) top separation and `0.5rem` (8dp) bottom separation.
  - Card-to-card stacking maintains `0.75rem` (12dp) distance to preserve distinct card entity separation on mobile canvases.

## Elevation & Depth

Visual hierarchy uses a refined hybrid of subtle surface boundaries and low-diffusion ambient shadows to avoid cluttered visual noise during dense data entry.

- **Base Layer (Elevation 0):** Background canvas (`#F8FAFC`).
- **Card & Tile Surface (Elevation 1):** Solid `#FFFFFF`, fortified by a 1px solid border in `#E2E8F0` and an ambient shadow: `0px 4px 12px rgba(15, 23, 42, 0.06)`. This ensures clear separation even under screen dimming in server rooms.
- **Interactive / Focus States (Elevation 2):** On tap/drag, cards transition to an ambient shadow of `0px 8px 20px rgba(56, 76, 157, 0.12)` with no border expansion.
- **Floating Action Button & Sticky Anchors (Elevation 3):** Drop shadow `0px 6px 16px rgba(216, 35, 42, 0.28)`, creating distinct tactical prominence for quick-entry routines.
- **Bottom Navigation Bar & Modals (Elevation 4):** Surface `#FFFFFF` layered over a directional shadow `0px -2px 10px rgba(15, 23, 42, 0.04)` combined with a 1px `#E2E8F0` top border.

## Shapes

The design system employs a refined modern curvature (`roundedness: 2`) with an 8dp (0.5rem) baseline and 16dp (1rem) container radius, aligning with Material Design 3 surface conventions.

- **Surfaces & Cards:** `1rem` (16px / `rounded-lg`) corner radius for standard cards, operational summary blocks, and modal sheets.
- **Input Fields & Search Bars:** `0.75rem` (12px) radius for outlined and filled input containers.
- **Status Chips & Pills:** Full pill-shaped radius (`9999px`) to distinguish categorical tags from interactive action buttons.
- **Buttons (Primary/Outlined):** `0.75rem` (12px) for balanced tactical ergonomics.
- **Material 3 Curved Header:** Top app bar background features a distinctive smooth bottom curvature (`1.5rem` / 24px bottom-left and bottom-right radii) to give the school’s administrative portal an authoritative yet polished visual identity.

## Components

### Top App Bar (Curved Header)
- Background: Deep Navy Blue (`#384C9D`) with pure white typography.
- Shape: Flat top, `1.5rem` (24px) radius on bottom corners.
- Contents: School/system identity ("LABKOM SMK Al-Madani"), profile shortcut, active lab location selector dropdown (e.g., "Lab TKJ 1"), and notification bell with Red badge indicator.

### Elevated Cards & Asset Tiles
- Background: Pure White (`#FFFFFF`).
- Border: 1px solid `#E2E8F0`. Shadow: `0px 4px 12px rgba(15, 23, 42, 0.06)`.
- Content Layout: Top row contains Asset Name and Status Pill; middle displays tabular metadata (Serial Tag, PC Number, Lab Room); bottom row holds quick actions (Audit, Edit, Report Defect).
- Supervisory Cards: Feature a 4px primary navy left-border accent to denote administrative or verification cards.

### Buttons & FAB
- **Primary Action:** Solid Deep Navy (`#384C9D`), text `#FFFFFF`, height 48px, radius 12px.
- **Destructive / Alert Action:** Solid Crimson Red (`#D8232A`), text `#FFFFFF`.
- **Secondary / Ghost Button:** Transparent background, 1.5px outline in `#384C9D` or `#E2E8F0`, text `#1E293B`.
- **Floating Action Button (FAB):** Material 3 Extended or Large Circular FAB in Crimson Red (`#D8232A`) with pure white icon (e.g., Barcode / QR Scanner icon), positioned at the bottom-right above the navigation bar.

### Status Badges & Chips
- **Nominal / In-Service:** Background `#ECFDF5`, text `#065F46`, 1px solid `#A7F3D0`.
- **Pending Verification:** Background `#FEF9C3`, text `#854D0E`, 1px solid `#FDE047` (Vibrant Gold theme).
- **Critical Stock / Damaged / Overdue:** Background `#FEF2F2`, text `#991B1B`, 1px solid `#FECACA`.
- **Category / Spec Tag:** Neutral background `#F1F5F9`, text `#475569`.

### Input Fields
- Filled variant has `#F8FAFC` background with a bottom indicator in `#384C9D`.
- Outlined variant uses a 1px border `#CBD5E1`, focusing to a 2px `#384C9D` border.
- Prefix and suffix icons are mandatory for scannable fields (e.g., Barcode Scanner icon inside Asset Code input).

### Segmented Control Tabs
- Used for switching lab rooms (Lab TKJ 1, Lab TKJ 2, Server Room) or status filters (Semua, Aktif, Rusak).
- Container: `#F1F5F9` background, `0.75rem` radius.
- Active Segment: Pure White (`#FFFFFF`) card elevation with subtle shadow and `#1E293B` bold typography.

### Bottom Navigation Bar
- Background: `#FFFFFF` with top border `1px solid #E2E8F0`.
- Active Item: Deep Navy Blue (`#384C9D`) icon with soft navy container pill background (`#EEF2FF`), text `#384C9D` bold.
- Inactive Item: Muted Slate (`#64748B`) icon and text.
- Standard 4-Destination Setup: Dashboard, Aset Lab, Verifikasi / Permohonan, Laporan.