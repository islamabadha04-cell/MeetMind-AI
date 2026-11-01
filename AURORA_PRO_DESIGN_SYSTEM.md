# AURORA PRO — Design System & UI Specification
**Intelligent Productivity Workspace Architecture**
**Version:** 2.4.0 (2026 Production Standard)

---

## 1. Design Vision & Philosophy
**AURORA PRO** redefines MeetMind AI into a world-class, international SaaS product.
- **Inspiration:** Apple-level clarity, Linear-style density, and modern AI workspace elegance.
- **Brand Identity:** Deep violet signature palette symbolizing intelligent automation, bilingual clarity, and trustworthy execution.
- **Purity:** Functional density with generous breathing room, intentional hierarchy, and zero gimmicks.

---

## 2. Color System & Semantic Tokens

### Light Mode (`[data-theme="light"]`)
| Token Name | Hex Value | Usage / Semantic Role |
| :--- | :--- | :--- |
| `--bg-app` | `#F6F5FA` | Primary page background |
| `--bg-sidebar` | `#FFFFFF` | Navigation drawer & sidebar |
| `--bg-card` | `#FFFFFF` | Surface containers, dashboard cards |
| `--bg-surface` | `#F0EEF8` | Table headers, secondary badges, inner pods |
| `--primary` | `#6D5CE7` | Signature Aurora Violet (brand & primary actions) |
| `--primary-hover`| `#5A49D8` | Interactive active/hover state |
| `--primary-soft` | `rgba(109, 92, 231, 0.08)` | Active navigation background tint |
| `--secondary` | `#8B72ED` | Secondary purple accents & chips |
| `--text-main` | `#26243A` | High-contrast headings and body text |
| `--text-muted` | `#858195` | Subtitles, supporting metadata |
| `--text-dim` | `#A29EAF` | Placeholders, inactive icons, timestamps |
| `--border-color`| `#E9E6F1` | Primary component borders |
| `--success` | `#20A67A` | Cloud status, completed actions, positive trends |
| `--warning` | `#E6A23C` | Pending reviews, trial notices |
| `--danger` | `#DB5866` | Destructive actions, recording alerts, errors |

### Dark Mode (`[data-theme="dark"]`)
| Token Name | Hex Value | Usage / Semantic Role |
| :--- | :--- | :--- |
| `--bg-app` | `#0D1020` | Obsidian workspace background |
| `--bg-sidebar` | `#111529` | Deep navy sidebar container |
| `--bg-card` | `#171A2C` | Elevated card surfaces |
| `--bg-surface` | `#1E2238` | Internal cards, sub-rows, inputs |
| `--primary` | `#8875FF` | Luminous violet primary CTA |
| `--primary-hover`| `#9B8AFF` | Luminous violet hover |
| `--primary-soft` | `rgba(136, 117, 255, 0.12)` | Subtle menu-item active indicator |
| `--secondary` | `#A78BFA` | Secondary purple text & accents |
| `--text-main` | `#F6F4FF` | Crisp high-contrast readable white |
| `--text-muted` | `#9294AC` | Subdued metadata, secondary labels |
| `--border-color`| `#292D43` | Dark mode container borders |

---

## 3. Typography Architecture

### Font Families
- **Primary Body & Display:** `'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- **Monospace & Numerical Data:** `'JetBrains Mono', 'SF Mono', Menlo, Consolas, monospace`
  - Utilized for: Waveform timers (`00:00:00`), stat values (`#statTotalMeetings`, `#statTotalAudio`, `#statOpenTasks`), timestamp jump buttons, and pricing indicators.
  - Mandatory setting: `font-variant-numeric: tabular-nums;` to prevent layout jitter during live updates.
- **Urdu Nastaliq System:** `'Noto Nastaliq Urdu', 'Jameel Noori Nastaleeq', 'Urdu Typesetting', serif`
  - Direction: `direction: rtl; text-align: right; line-height: 2.1;`

---

## 4. Component Hierarchy

### Navigation Sidebar (Linear Productivity Style)
- Category headers: `WORKSPACE`, `AI INTELLIGENCE`, `AUTOMATION & TASKS`, `COLLABORATION`, `LEGAL & TRUST`.
- Active items utilize subtle tinted background (`--primary-soft`) with a 3.5px rounded left vertical indicator bar, avoiding blocky saturated fills.
- Icon alignment: Standardized 17px Remix / Lucide icons with 0.15s subtle scale transition on hover.

### Universal Top Bar
- Sticky 64px header with glassmorphism backdrop blur (`backdrop-filter: blur(12px)`).
- Search input with inline `<kbd class="search-kbd">⌘K</kbd>` shortcut indicator.
- Live backend connectivity pill preserving verified health status.
- Light/Dark mode switcher with smooth CSS transitions.

### Dashboard Hero & Action Grid
- Personalized welcome greeting with productivity encouragement.
- Radiant Aurora Violet recording card with live pulse indicator and prominent "Launch Studio" CTA.
- 3 mini quick actions (`Upload Audio`, `Import Link`, `Upload Document`) with soft pastel tinted icon containers.

### KPI Statistics (3 Cards)
- `Total Meetings`: Tabular figures with live device status.
- `Audio Captured`: Tabular time breakdown (hours + minutes) with tag metadata.
- `Open Tasks`: Pending action item count linked to active meeting outcomes.

### Recording Studio
- Centered audio visualizer canvas supporting 60 FPS real-time speech waveform rendering.
- Tabular monospace timer (`#studioLiveTimer`).
- Language selector chips (`English`, `اردو (Urdu)`, `پنجابی (Punjabi)`, `Roman Urdu`).
- Explicit participant consent disclosure banner.

---

## 5. Responsive Grid & Breakpoints
- **Desktop (1440px+):** 240px fixed sidebar, 3-column dashboard split (`1.6fr : 1.1fr : 1.1fr`).
- **Laptop (1024px – 1280px):** 200px sidebar, 2-column action grid, single-column main feed.
- **Tablet & Mobile (360px – 768px):** Collapsible off-canvas drawer navigation, single-column stacked cards, full-width actions, touch-optimized targets (>= 44px).
