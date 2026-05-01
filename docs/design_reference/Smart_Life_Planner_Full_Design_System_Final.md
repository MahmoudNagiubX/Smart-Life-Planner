# Smart Life Planner — Full App UI/UX Design System for Google Stitch, Codex, and Claude Code

> **Version:** Final expanded design system with locked colors, typography, dark mode, radius, shadows, navigation, and Flutter handoff tokens.
> **Bottom Navigation:** Home — Tasks — Focus — Prayer — Profile.

---

> **Purpose of this file:**  
> Use this document as the master design prompt/specification for Google Stitch to design the complete Smart Life Planner mobile application.  
> The design must use the uploaded **App Preview** image as the strongest visual reference. The **Home screen must be a near-clone of that preview**, and all other screens must follow the same premium, clean, calm, modern productivity style.

---

## 0. How Google Stitch Must Use This File

### 0.1 Upload these references before using this prompt

Upload these images/files in this order:

1. **App Preview image**  
   - This is the master visual reference.  
   - The Home screen must match it as closely as possible.
   - Use the same premium light lavender background, rounded cards, purple/pink gradients, calm spacing, soft shadows, and clean dashboard hierarchy.

2. **Smart Life Planner logo/app icon**  
   - Use only for brand identity, icon style, app logo, and color direction.
   - Do not redesign the logo unless explicitly asked.

3. **Optional UI style reference**  
   - Use only for additional polish.
   - Do not override the App Preview style.

### 0.2 Design priority order

Google Stitch must follow this priority:

1. **Match the App Preview visual style first.**
2. Preserve the official app navigation and user flows.
3. Make every screen feel like part of one unified design system.
4. Use best practices from premium productivity apps, but do not copy them:
   - TickTick-inspired task clarity and fast capture
   - Notion-inspired clean structure and modular content blocks
   - Focus To-Do-inspired focus timer clarity
   - Google Keep-inspired notes grid, color chips, and fast note capture
5. Keep all screens Flutter-ready and mobile-first.

### 0.3 Critical instruction

Do **not** generate random unrelated screens.  
Do **not** use a different visual style per page.  
Do **not** make the app dark/cosmic.  
Do **not** create cluttered dashboards.  
Do **not** hide Prayer, Focus, AI, or Quick Capture.

The whole app must feel like one product:  
**Premium. Clean. Calm. Modern. Spiritual. AI-powered. Productivity-focused.**

---

# 1. Product Identity

## 1.1 App name

**Smart Life Planner**

## 1.2 Tagline options

Use one of these when needed:

- Plan Smart. Live Better.
- Your AI-powered life operating system.
- Capture. Focus. Reflect. Grow.
- Productivity, habits, prayer, and AI planning in one calm system.

## 1.3 Product definition

Smart Life Planner is an **AI-powered personal life operating system** that combines:

- tasks
- projects
- notes
- habits
- focus sessions
- journaling
- reminders
- prayer routines
- Quran goals
- AI planning
- voice input
- analytics
- adaptive scheduling

The app should not feel like a simple to-do list.  
It should feel like a calm intelligent assistant that helps the user manage their day, reduce mental overload, stay focused, and balance productivity with spiritual consistency.

## 1.4 Brand personality

The visual design must feel:

- premium
- clean
- calm
- modern
- trustworthy
- intelligent
- friendly
- spiritually respectful
- focused
- soft but powerful
- not childish
- not corporate-heavy
- not overwhelming

## 1.5 Emotional goal

When users open the app, they should feel:

- “I know what to do next.”
- “My day is organized.”
- “My spiritual routine is visible.”
- “I can capture things quickly.”
- “The app is helping me, not stressing me.”
- “This is one place for everything.”

---

# 2. Target Users

Design the app for:

1. **Students**
   - assignments
   - exams
   - study plans
   - focus sessions
   - deadlines
   - quick notes

2. **Busy workers**
   - tasks
   - meetings
   - projects
   - reminders
   - work-life balance

3. **Muslims who want prayer + productivity**
   - prayer times
   - prayer tracking
   - Quran goals
   - Ramadan support
   - spiritually aware planning

4. **People who want AI planning**
   - natural language task capture
   - AI task breakdown
   - daily plan suggestions
   - next best action
   - schedule assistance

5. **Beginners who need simple task management**
   - very clear buttons
   - friendly empty states
   - minimal complexity
   - guided onboarding

6. **People who want an all-in-one app**
   - tasks
   - notes
   - habits
   - focus
   - prayer
   - journal
   - analytics
   - AI assistant

7. **People who want AI in productivity management**
   - AI must feel accessible from Home, Tasks, Quick Capture, and Planning.
   - AI should suggest and explain, not force actions.

---

# 3. Main Navigation Style

## 3.1 Official bottom navigation

Use this top-level structure:

1. **Home**
2. **Tasks**
3. **Focus**
4. **Prayer**
5. **Profile**

### Why this navigation

- Home = daily command center.
- Tasks = productivity management.
- Focus = deep work and Pomodoro.
- Prayer = spiritual routine, Quran, Qibla, Ramadan.
- Profile = settings, analytics, account, preferences.

## 3.2 Floating quick action button

Use a premium floating center **+** button in the bottom navigation area.

### Placement

- Center bottom, slightly raised above the nav bar.
- Circular, 60–66 px.
- Purple-to-pink gradient.
- White plus icon.
- Soft glow/shadow.

### Action

Tap opens **Quick Capture Bottom Sheet**.

Quick Capture must allow:

- add task
- add note
- add habit
- add reminder
- voice capture
- AI parse / organize

## 3.3 Nested navigation

Use nested screens like this:

### Home nested modules

- Notes
- Habits
- Journal
- Home Insights
- AI Planner shortcut
- Quick Capture
- Daily Review shortcut

### Tasks nested modules

- Inbox
- Today
- Upcoming
- Projects
- Completed
- Task Details
- Create/Edit Task
- Project Details
- Schedule/Calendar View

### Focus nested modules

- Focus Home
- Active Focus Session
- Session Complete
- Focus History
- Focus Settings

### Prayer nested modules

- Prayer Home
- Prayer Times
- Prayer Tracking
- Prayer History
- Quran Goals
- Qibla
- Ramadan Mode
- Prayer Settings
- Athan Settings
- Missed Prayer Tracking
- Future: Dhikr Reminders
- Future: Islamic Calendar
- Future: Fasting Tracker

### Profile nested modules

- Profile Home
- Account
- Settings
- Notifications Settings
- Appearance
- Language
- Analytics
- Data & Privacy
- Help & Support
- About
- Change Password
- Sign Out

---

# 4. Layout System

Use these layout rules across the entire app.

## 4.1 Mobile canvas

Primary design size:

- iPhone-like portrait screen
- 390 × 844 px or 430 × 932 px
- 9:16 ratio
- Safe areas respected
- Rounded phone preview if presenting mockups

## 4.2 App background

- Light lavender/off-white background.
- Very soft gradient.
- Subtle abstract circles or curves.
- Minimal sparkles only on special hero cards.
- Never overpower content.

## 4.3 Page padding

Use consistent page padding:

- horizontal screen padding: **20 px**
- top content spacing after safe area: **16–20 px**
- section spacing: **16–22 px**
- card internal padding: **16–24 px**
- bottom content padding above nav: **110–130 px**

## 4.4 Grid

Use a simple 2-column responsive grid for dashboard cards:

- gap between cards: **14–16 px**
- full-width cards for important summaries
- half-width cards for paired summaries

## 4.5 Card radius

- Large cards: **28–30 px**
- Medium cards: **24–26 px**
- Small cards: **20–24 px**
- Input fields: **18–22 px**
- Pills/buttons: **999 px / fully rounded**

## 4.6 Button height

- Primary button: **52–56 px**
- Secondary button: **46–52 px**
- Small card button: **40–44 px**
- Icon button: **42–48 px**
- Bottom nav height: **76–86 px**

## 4.7 Icon sizes

- Bottom nav icon: **24 px**
- Card header icon: **20–22 px**
- Action button icon: **22–24 px**
- Large empty-state icon/illustration: **96–160 px**
- Avatar: **42–48 px**
- App logo in header: **48 px**

## 4.8 Screen rhythm

Every screen should follow this rhythm:

1. top safe area
2. header / app bar
3. primary action or hero content
4. main list/cards
5. secondary content
6. floating bottom navigation / safe bottom spacing

---

# 5. Component Style

## 5.1 Buttons

### Primary button

Use for main actions:

- Create Task
- Start Focus
- Save
- Continue
- Confirm
- Begin
- Add

Style:

- full width when in forms
- gradient background
- height 52–56 px
- rounded pill
- white text
- subtle glow
- icon optional on left

### Secondary button

Use for less important actions:

- Cancel
- Skip
- View all
- Later
- Edit

Style:

- white background
- soft lavender border
- purple text
- rounded pill
- height 44–52 px

### Ghost/text button

Use for links:

- Forgot password
- Resend code
- View all
- Learn more
- Change

Style:

- no background
- purple text
- medium font weight

### Destructive button

Use for:

- Delete task
- Delete note
- Log out
- Remove account

Style:

- soft red background
- red text
- never use harsh full red unless confirmation screen

---

## 5.2 Text fields

Use consistent input fields:

- height 54–58 px
- rounded 20–22 px
- soft lavender fill
- subtle border
- label above or floating
- icon on left for common fields
- clear validation messages below
- error state with red border and friendly text

For long text / notes:

- multi-line container
- large radius 24 px
- placeholder text
- toolbar only when needed

---

## 5.3 Cards

Cards are the main building block.

Style:

- white or soft lavender fill
- radius 24–30 px
- soft shadow
- optional glass border
- clear header
- strong hierarchy
- never cramped

Card types:

- dashboard summary card
- task card
- project card
- note card
- habit card
- focus card
- prayer card
- AI suggestion card
- analytics card
- settings card

---

## 5.4 Task cards

Task card layout:

- left status circle/check
- title
- subtitle row: project/category/time/priority
- right badge or progress
- optional swipe actions
- optional subtasks/progress bar

Task card states:

- active
- completed
- overdue
- blocked
- high priority
- recurring
- has reminder
- AI suggested

---

## 5.5 Note cards

Use Google Keep-inspired but premium:

- masonry/staggered grid on Notes list
- rounded 22–26 px
- optional soft pastel background
- title
- preview
- tags
- pinned icon
- reminder icon
- optional image thumbnail
- optional checklist preview
- optional voice note waveform

Note actions:

- tap opens editor
- long press selects
- swipe/archive option
- pin/unpin
- add color/tag
- search/filter

---

## 5.6 Calendar / schedule cards

Use for daily schedule and upcoming items:

- timeline layout
- time on left
- event/task block on right
- color strip by category
- prayer windows clearly visible
- focus blocks visually distinct
- locked blocks have lock icon
- AI-generated blocks have sparkle icon

---

## 5.7 AI suggestion cards

AI cards must feel helpful, not intrusive.

Style:

- subtle gradient or white card with purple accent
- sparkle icon
- short explanation
- CTA: “Preview plan”, “Ask AI”, “Apply after review”
- always allow user to dismiss

Never silently apply changes from AI.

---

## 5.8 Empty states

Every empty state must include:

- friendly icon/illustration
- short title
- helpful sentence
- one primary action
- optional secondary action

Example:

Title: “No tasks for today”  
Text: “Capture your first task or let AI help you plan your day.”  
Primary: “Add task”  
Secondary: “Ask AI”

---

## 5.9 Dialogs

Use dialogs only for important confirmation:

- delete
- logout
- discard changes
- permission explanation
- AI confirmation for write actions

Style:

- rounded 28 px
- large title
- short explanation
- primary + secondary buttons
- avoid long paragraphs

---

## 5.10 Bottom sheets

Use bottom sheets for quick actions:

- quick capture
- quick edit
- task status change
- voice confirmation
- AI parsed preview
- habit log
- prayer mark confirmation
- reminder setup

Style:

- draggable handle
- rounded top corners 30 px
- white surface
- soft shadow
- content scrollable if needed
- primary action pinned at bottom when form is long

---

## 5.11 Loading states

Use:

- skeleton shimmer for lists/cards
- circular loader only for small buttons
- full-screen loader only for splash/session check
- AI typing animation for AI responses

Do not leave blank screens while loading.

---

## 5.12 Error states

Use:

- friendly error card
- retry button
- optional “offline mode” explanation
- never show raw backend errors

---

## 5.13 No internet state

Show a small offline banner:

- top of screen below header
- text: “You’re offline. Changes will sync later.”
- soft amber/lavender style
- not scary

For screens requiring internet:

- show cached data if available
- otherwise show offline empty state with retry

---

# 6. Main User Flow

## 6.1 First-time user flow

1. Splash screen
2. Welcome screen
3. Sign up / sign in
4. Email verification if enabled
5. Onboarding:
   - language
   - city/country
   - prayer method
   - goals
   - wake time
   - sleep time
   - notification permission
   - microphone permission
   - location permission
   - summary
6. App config is created
7. User lands on Home dashboard
8. User sees:
   - daily progress
   - next prayer
   - focus shortcut
   - today tasks
   - habits
   - AI suggestion

## 6.2 Returning user daily flow

1. Open app
2. Land on Home
3. Check top tasks and next prayer
4. Quick-add a task or note using floating plus
5. Start focus session
6. Mark task/habit/prayer
7. Review progress
8. Add journal reflection at night
9. View analytics later from Profile

## 6.3 Quick capture flow

1. User taps floating plus button
2. Quick Capture bottom sheet opens
3. User chooses:
   - task
   - note
   - habit
   - reminder
   - voice
   - AI capture
4. User enters text or voice
5. If AI is used, show parsed preview
6. User confirms or edits
7. Save
8. Show success animation and update Home

## 6.4 AI planning flow

1. User taps AI suggestion / Ask AI
2. AI screen opens
3. User asks for help or selects prompt chip
4. AI suggests:
   - task breakdown
   - daily plan
   - focus suggestion
   - next action
5. User previews suggested changes
6. User confirms selected actions
7. App saves only confirmed changes

## 6.5 Prayer flow

1. User sees next prayer on Home
2. Taps “View Prayer Times”
3. Prayer screen opens
4. User sees all prayer times and tracking
5. User marks prayer as completed
6. Prayer progress updates Home

## 6.6 Focus flow

1. User taps Start Focus from Home or Focus tab
2. Active Focus Session opens
3. Timer starts
4. User can pause/stop
5. Session complete screen appears
6. User can log result or start break
7. Focus stats update Home

---

# 7. States Required for Every Page

Every screen must have these states:

## 7.1 Normal state

- real content visible
- primary action clear
- bottom navigation accessible if inside main shell

## 7.2 Loading state

- skeleton card/list placeholders
- maintain layout to avoid jumping
- do not show blank white pages

## 7.3 Empty state

- friendly illustration
- helpful text
- primary action
- optional AI help

## 7.4 Error state

- friendly message
- retry button
- support link only if useful

## 7.5 Success state

- subtle check animation
- toast/snackbar
- updated card/list immediately

## 7.6 No internet state

- offline banner
- cached content
- sync later message

## 7.7 Permission denied state

Use for:

- location
- microphone
- notifications

Must include:

- explanation
- “Try again” button
- “Use manual setup” fallback when possible

---

# 8. Animation Style

## 8.1 Overall animation level

Use polished subtle animation, not excessive effects.

The app should feel:

- smooth
- responsive
- premium
- calm

## 8.2 Page transitions

- main tabs: subtle fade/slide
- detail screens: right-to-left slide
- bottom sheets: slide up + blur
- modals: scale/fade
- onboarding: horizontal step transition

## 8.3 Card interactions

On press:

- slight scale down to 0.98
- shadow reduces
- quick haptic feedback if available

## 8.4 Task completion animation

When user completes a task:

- checkmark circle fills with gradient
- row slightly fades or moves to completed style
- small sparkle/confetti only for important milestones
- keep it elegant

## 8.5 AI typing animation

AI response:

- animated dots
- small robot/sparkle motion
- message fades in line by line
- show structured preview cards, not only text

## 8.6 Bottom sheet animation

- slide from bottom
- rounded corners
- background dim/blur
- drag handle appears
- primary button sticks at bottom for forms

## 8.7 Focus timer animation

- circular progress ring moves smoothly
- pulse/glow every minute or phase change
- calming micro-animation, not distracting
- completion ring closes smoothly

## 8.8 Loading skeletons

- soft shimmer in lavender/white
- card skeletons match actual card shape
- lists show 3–5 skeleton rows

## 8.9 Navigation bar animation

- active tab icon slightly pops
- active dot fades/slides
- center plus button has subtle glow
- no exaggerated bouncing

---

# 9. Final Design System — Locked Brand Tokens

> These tokens are selected from the uploaded references: the premium Smart Life Planner home screen, the purple/pink file-management UI references, and the soft modern mobile dashboard reference.  
> Codex, Claude Code, Google Stitch, and Flutter developers must use these tokens as the source of truth unless the product owner explicitly changes them.

## 9.1 Brand tokens

- **App logo:** Smart Life Planner logo/app icon; rounded-square purple/pink gradient with checklist/orbit/sparkle identity.
- **App icon usage:** 48 px in headers, 56–64 px on splash/welcome, 28–32 px in compact places.
- **Brand mood:** Premium, clean, calm, modern, spiritual, AI-powered productivity.
- **Visual keywords:** soft lavender, glowing gradients, rounded cards, calm white space, clean dashboard, gentle glassmorphism, subtle 3D/illustrative accents.
- **Illustration style:** soft 2.5D/3D-like pastel illustrations, not childish, not realistic, not noisy.
- **Icon style:** rounded line icons, 2 px stroke, occasional filled gradient icon bubbles for feature cards.
- **Main reference screen:** uploaded Smart Life Planner Home preview. Home must remain a near-clone.
- **Secondary references:** purple/pink file app screens and clean modern rounded dashboard UI references.
- **Primary navigation:** Home — Tasks — Focus — Prayer — Profile.
- **Primary action:** floating Quick Capture / Add button, visually separated from the five navigation tabs.

## 9.2 Color tokens

### Light mode core palette

| Token | Hex | Usage |
|---|---:|---|
| `brandPrimary` | `#6A4CFF` | active icons, primary actions, progress rings, links |
| `brandPrimaryDeep` | `#4F3BEF` | gradient start, pressed states |
| `brandViolet` | `#8B5CFF` | secondary gradient, icon bubbles |
| `brandPink` | `#F45DB3` | secondary actions, focus accents, gradient end |
| `brandPinkSoft` | `#FFEAF6` | pink chip backgrounds |
| `brandGold` | `#FFD45C` | highlights such as “balanced”, sparkles, premium accents |
| `brandCyan` | `#39D7E8` | optional informational accent, storage/notes style chips |
| `appBackground` | `#F8F6FF` | main app background |
| `appBackgroundAlt` | `#F1ECFF` | soft background blobs and panels |
| `surface` | `#FFFFFF` | main cards, inputs, sheets |
| `surfaceSoft` | `#FBFAFF` | secondary card fill |
| `surfaceLavender` | `#F3EFFF` | icon bubbles, selected chips |
| `textPrimary` | `#17163B` | headings and important labels |
| `textSecondary` | `#6F6B8E` | subtitles and metadata |
| `textMuted` | `#9A95B8` | placeholders, timestamps, disabled text |
| `borderSoft` | `#EEE9FF` | card/input borders |
| `divider` | `#E7E1F7` | dividers inside lists/cards |
| `whiteTransparent` | `rgba(255,255,255,0.74)` | glass surfaces |

### Semantic colors

| Token | Hex | Usage |
|---|---:|---|
| `success` | `#2ED47A` | completed tasks, success states |
| `successSoft` | `#E8FFF3` | success chips and backgrounds |
| `warning` | `#FFB547` | warnings, deadline risk, caution |
| `warningSoft` | `#FFF4DC` | warning chips |
| `error` | `#FF4D6D` | destructive actions, errors |
| `errorSoft` | `#FFE8EE` | error surfaces |
| `info` | `#4DA3FF` | info banners, learning tips |
| `infoSoft` | `#EAF4FF` | info backgrounds |

### Feature accent colors

| Feature | Main | Soft background |
|---|---:|---:|
| Tasks | `#6A4CFF` | `#F0E9FF` |
| Notes | `#FFB547` | `#FFF4DC` |
| Habits | `#25C68A` | `#E8FFF3` |
| Focus | `#F45DB3` | `#FFEAF6` |
| Prayer | `#8B5CFF` | `#F1ECFF` |
| AI Assistant | `#7C5CFF` | `#F3EFFF` |
| Journal | `#39D7E8` | `#E8FBFF` |
| Analytics | `#4DA3FF` | `#EAF4FF` |

## 9.3 Gradient tokens

| Token | Value | Usage |
|---|---|---|
| `gradientBrandMain` | `linear-gradient(135deg, #5C49F4 0%, #8A4FFF 48%, #F26AA8 100%)` | Home summary card, splash highlights |
| `gradientAction` | `linear-gradient(135deg, #6A4CFF 0%, #F45DB3 100%)` | primary buttons, center add button |
| `gradientFocus` | `linear-gradient(135deg, #6A4CFF 0%, #FF6CA8 100%)` | focus timer ring and focus CTA |
| `gradientPrayer` | `linear-gradient(135deg, #EEE9FF 0%, #FFFFFF 45%, #F8F6FF 100%)` | prayer cards |
| `gradientAI` | `linear-gradient(135deg, #F8F6FF 0%, #FFFFFF 50%, #EEE9FF 100%)` | AI suggestion cards |
| `gradientDark` | `linear-gradient(135deg, #151433 0%, #211B4E 55%, #3A215B 100%)` | dark mode hero cards |
| `gradientWarning` | `linear-gradient(135deg, #FFB547 0%, #FF7A59 100%)` | deadline warnings |

## 9.4 Typography tokens

### Font decision

- **English heading font:** `Plus Jakarta Sans` preferred. Fallback: `Poppins`, `Inter`, `SF Pro Display`.
- **English body font:** `Inter` preferred. Fallback: `Plus Jakarta Sans`, `Roboto`.
- **Button font:** `Plus Jakarta Sans` or `Inter`, 700 weight.
- **Number font:** `Inter` with tabular numbers where available.
- **Arabic heading font:** `Cairo` preferred. Fallback: `Tajawal`.
- **Arabic body font:** `Tajawal` preferred. Fallback: `Cairo`.

> Flutter note: if the project already uses `google_fonts`, use `GoogleFonts.plusJakartaSans`, `GoogleFonts.inter`, `GoogleFonts.cairo`, and `GoogleFonts.tajawal`. If not, use the existing app font and map the same sizes/weights.

### Text hierarchy

| Token | Size | Weight | Line height | Usage |
|---|---:|---:|---:|---|
| `displayLarge` | 34 | 800 | 40 | welcome hero, major onboarding title |
| `h1` | 28 | 800 | 34 | screen titles |
| `h2` | 24 | 800 | 30 | major cards, Home summary title |
| `h3` | 20 | 700 | 26 | section headers |
| `h4` | 17 | 700 | 23 | card titles |
| `bodyLarge` | 16 | 500 | 24 | regular readable paragraphs |
| `body` | 14 | 500 | 21 | standard labels/subtitles |
| `bodySmall` | 13 | 500 | 18 | card metadata |
| `caption` | 12 | 500 | 16 | timestamps, helper text |
| `label` | 12 | 700 | 16 | chips, status pills |
| `button` | 15 | 700 | 20 | primary/secondary buttons |
| `navLabel` | 11 | 600 | 14 | bottom nav labels |
| `timerNumber` | 32 | 800 | 38 | focus timer number |
| `metricNumber` | 30 | 800 | 36 | progress and analytics numbers |

### RTL / Arabic typography rules

- Arabic screens must use RTL layout and Arabic fonts.
- Icons with direction must flip in RTL: back arrows, chevrons, progress direction when relevant.
- Keep Arabic line height slightly larger: +2 px compared with English.
- Avoid overly small Arabic text below 12 px.
- Keep mixed Arabic/English numbers readable and aligned.

## 9.5 Spacing tokens

Use an 8 px grid with 4 px micro-adjustments.

| Token | Value | Usage |
|---|---:|---|
| `space2` | 2 | tiny icon/text adjustments |
| `space4` | 4 | compact gaps |
| `space6` | 6 | chip inner gap |
| `space8` | 8 | row gap, small card spacing |
| `space12` | 12 | item padding, icon/text gap |
| `space16` | 16 | default component gap |
| `space20` | 20 | screen horizontal padding |
| `space24` | 24 | major section spacing |
| `space28` | 28 | large cards and top spacing |
| `space32` | 32 | onboarding sections |
| `space40` | 40 | hero/splash spacing |

### Layout defaults

- `screenPadding`: 20 px
- `screenPaddingCompact`: 16 px for very small devices
- `sectionGap`: 20 px
- `cardGap`: 16 px
- `cardPadding`: 18–20 px
- `listItemGap`: 10–12 px
- `bottomNavHeight`: 76–84 px
- `bottomSafePadding`: device safe area + 12 px
- `appBarHeight`: 56–64 px
- `inputHeight`: 52–56 px
- `buttonHeight`: 48–54 px
- `largeButtonHeight`: 56 px

## 9.6 Radius tokens

| Token | Value | Usage |
|---|---:|---|
| `radiusXS` | 6 | small badges, progress bars |
| `radiusSM` | 10 | small icon containers |
| `radiusMD` | 14 | chips, compact inputs |
| `radiusLG` | 18 | list rows, note cards |
| `radiusXL` | 22 | medium cards, bottom sheet top corners |
| `radius2XL` | 26 | dashboard cards |
| `radius3XL` | 30 | hero cards and large panels |
| `radiusPhone` | 40 | phone mockup / preview only |
| `radiusPill` | 999 | buttons, chips, nav indicators |

## 9.7 Shadow tokens

Use soft shadows only. No harsh black shadows.

### Flutter-style BoxShadow tokens

```dart
// Card shadow
BoxShadow(
  color: Color(0xFF6A4CFF).withOpacity(0.10),
  blurRadius: 24,
  offset: Offset(0, 10),
)

// Soft white card shadow
BoxShadow(
  color: Color(0xFF17163B).withOpacity(0.06),
  blurRadius: 22,
  offset: Offset(0, 8),
)

// Floating nav / FAB shadow
BoxShadow(
  color: Color(0xFF6A4CFF).withOpacity(0.22),
  blurRadius: 28,
  offset: Offset(0, 12),
)

// Pink glow shadow
BoxShadow(
  color: Color(0xFFF45DB3).withOpacity(0.20),
  blurRadius: 30,
  offset: Offset(0, 10),
)

// Dark mode card shadow
BoxShadow(
  color: Color(0xFF000000).withOpacity(0.28),
  blurRadius: 26,
  offset: Offset(0, 12),
)
```

### Named shadow tokens

| Token | Usage |
|---|---|
| `shadowSoft` | small cards and inputs |
| `shadowCard` | dashboard cards |
| `shadowFloating` | bottom nav, floating buttons |
| `shadowGlowPurple` | active purple components |
| `shadowGlowPink` | CTA and focus components |
| `shadowDark` | dark mode surfaces |

## 9.8 Component tokens

### Buttons

| Type | Height | Radius | Fill | Text |
|---|---:|---:|---|---|
| Primary | 52–56 | pill | `gradientAction` | white, 15/700 |
| Secondary | 48–52 | pill | white | `brandPrimary`, 15/700 |
| Ghost | 44–48 | pill | transparent | `brandPrimary`, 14/700 |
| Destructive | 48–52 | pill | `error` or `errorSoft` | white or `error` |
| Icon button | 42–48 | circle | white / soft lavender | icon 20–22 |

### Inputs

- Height: 52–56 px
- Radius: 18–22 px
- Background: white / `surfaceSoft`
- Border: `borderSoft`
- Focus border: `brandPrimary`
- Error border: `error`
- Prefix icons: 20–22 px, `textMuted`
- Label: 13–14 px
- Helper/error text: 12 px

### Cards

- Dashboard card: radius 26–30, padding 18–20, white, soft shadow.
- Task card: radius 18–22, height 64–84, icon bubble 42–46.
- Note card: radius 20–24, variable height, light pastel fills allowed.
- Prayer card: radius 26, spiritual illustration area, very soft purple/gold accents.
- Focus card: radius 26, circular timer center.
- AI card: radius 26, robot/sparkle accent, quote text, CTA link.
- Dialog: radius 28, padding 24, centered.
- Bottom sheet: top radius 28–32, drag handle, sticky primary action.
- Snackbar/toast: radius 16, floating above nav, semantic color icon.

---

# 10. Final Color Palette

## 10.1 Light mode

| Purpose | Token | Hex |
|---|---|---:|
| Primary color | `brandPrimary` | `#6A4CFF` |
| Primary pressed | `brandPrimaryDeep` | `#4F3BEF` |
| Secondary color | `brandViolet` | `#8B5CFF` |
| Accent color | `brandPink` | `#F45DB3` |
| Warm highlight | `brandGold` | `#FFD45C` |
| Optional cyan accent | `brandCyan` | `#39D7E8` |
| Background color | `appBackground` | `#F8F6FF` |
| Alternate background | `appBackgroundAlt` | `#F1ECFF` |
| Card color | `surface` | `#FFFFFF` |
| Soft card color | `surfaceSoft` | `#FBFAFF` |
| Lavender surface | `surfaceLavender` | `#F3EFFF` |
| Primary text | `textPrimary` | `#17163B` |
| Secondary text | `textSecondary` | `#6F6B8E` |
| Muted text | `textMuted` | `#9A95B8` |
| Border color | `borderSoft` | `#EEE9FF` |
| Divider color | `divider` | `#E7E1F7` |
| Success color | `success` | `#2ED47A` |
| Warning color | `warning` | `#FFB547` |
| Error color | `error` | `#FF4D6D` |
| Info color | `info` | `#4DA3FF` |

## 10.2 Dark mode

Dark mode must preserve the same calm premium identity, not become pure black/neon.

| Purpose | Token | Hex |
|---|---|---:|
| Dark background | `darkBackground` | `#0F1024` |
| Dark background alt | `darkBackgroundAlt` | `#141633` |
| Dark surface | `darkSurface` | `#191A3A` |
| Dark card | `darkCard` | `#202046` |
| Dark elevated card | `darkElevated` | `#27285A` |
| Dark primary | `darkPrimary` | `#8B7CFF` |
| Dark secondary | `darkSecondary` | `#B07CFF` |
| Dark accent | `darkPink` | `#FF6DB6` |
| Dark gold | `darkGold` | `#FFD96A` |
| Dark text primary | `darkTextPrimary` | `#F7F4FF` |
| Dark text secondary | `darkTextSecondary` | `#C8C2E6` |
| Dark text muted | `darkTextMuted` | `#918BAE` |
| Dark border | `darkBorder` | `#34345D` |
| Dark divider | `darkDivider` | `#2B2B50` |
| Dark success | `darkSuccess` | `#35D98B` |
| Dark warning | `darkWarning` | `#FFC15A` |
| Dark error | `darkError` | `#FF6B84` |
| Dark info | `darkInfo` | `#6CB6FF` |

## 10.3 Gradients

```text
Main brand gradient:  #5C49F4 → #8A4FFF → #F26AA8
Action gradient:      #6A4CFF → #F45DB3
Focus gradient:       #6A4CFF → #FF6CA8
Prayer soft gradient: #FFFFFF → #F4EFFF → #FFFFFF
AI soft gradient:     #FFFFFF → #F8F6FF → #EEE9FF
Dark hero gradient:   #151433 → #211B4E → #3A215B
Warning gradient:     #FFB547 → #FF7A59
Success gradient:     #2ED47A → #7BE7B7
```

## 10.4 Color usage rules

- Use purple as the dominant brand color.
- Use pink only for secondary highlights and CTAs, not every component.
- Use gold sparingly for premium highlights, not buttons everywhere.
- Keep the majority of screens white/lavender and calm.
- Use semantic colors only when meaning is clear.
- Dark mode must reduce glow intensity by 20–30%.

---

# 11. Final Typography System

## 11.1 English typography

- **Heading font:** Plus Jakarta Sans
- **Body font:** Inter
- **Button font:** Plus Jakarta Sans / Inter
- **Number font:** Inter, tabular numbers where possible

### English styles

```text
Display Large: 34 px / 800 / line height 40
H1:            28 px / 800 / line height 34
H2:            24 px / 800 / line height 30
H3:            20 px / 700 / line height 26
H4:            17 px / 700 / line height 23
Body Large:    16 px / 500 / line height 24
Body:          14 px / 500 / line height 21
Body Small:    13 px / 500 / line height 18
Caption:       12 px / 500 / line height 16
Label:         12 px / 700 / line height 16
Button:        15 px / 700 / line height 20
Bottom Nav:    11 px / 600 / line height 14
```

## 11.2 Arabic typography

- **Arabic heading font:** Cairo
- **Arabic body font:** Tajawal
- **Arabic button font:** Cairo or Tajawal, 700 weight

### Arabic styles

```text
Arabic H1:          28 px / 800 / line height 38
Arabic H2:          24 px / 800 / line height 34
Arabic H3:          20 px / 700 / line height 30
Arabic Body:        15 px / 500 / line height 24
Arabic Body Small:  13 px / 500 / line height 21
Arabic Caption:     12 px / 500 / line height 18
Arabic Button:      15 px / 700 / line height 22
```

## 11.3 Typography UX rules

- Never use more than 2 font families per language.
- Keep headings bold but not overly heavy.
- Use strong number hierarchy for focus timer, progress, prayer time, and analytics.
- Keep task titles readable at 14–15 px minimum.
- Keep labels/chips short.
- Avoid long paragraph blocks inside cards.
- Use sentence case for most UI labels.
- Use friendly microcopy.

---

# 11A. Flutter Implementation Handoff for Codex and Claude Code

> Use this section when converting the design into native Flutter.  
> The goal is to upgrade the existing Flutter app UI without breaking architecture, routing, providers, backend integration, or roadmap scope.

## 11A.1 Implementation principles

- Use native Flutter widgets only.
- Do not use WebView.
- Do not paste HTML/CSS/JSX into Flutter.
- Preserve existing Riverpod providers and route names where possible.
- Keep the official bottom navigation: **Home — Tasks — Focus — Prayer — Profile**.
- Add the floating Quick Capture button above the nav if the current shell supports it.
- Keep Home as a near-clone of the uploaded App Preview.
- Apply the same visual language to every screen.
- Do not implement deferred AI/spiritual/reminder features unless already in the app.
- Use real app data when providers exist; otherwise show honest empty states.
- Do not leave hardcoded fake production data.

## 11A.2 Recommended Flutter token files

Create or update these files depending on the current project structure:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_gradients.dart
lib/core/theme/app_text_styles.dart
lib/core/theme/app_spacing.dart
lib/core/theme/app_radius.dart
lib/core/theme/app_shadows.dart
lib/core/theme/app_theme.dart
lib/shared/widgets/app_card.dart
lib/shared/widgets/app_button.dart
lib/shared/widgets/app_icon_button.dart
lib/shared/widgets/app_chip.dart
lib/shared/widgets/app_bottom_sheet.dart
lib/shared/widgets/app_empty_state.dart
lib/shared/widgets/app_error_state.dart
lib/shared/widgets/app_loading_skeleton.dart
lib/shared/widgets/progress_ring.dart
```

## 11A.3 Recommended Flutter constants

```dart
class AppColors {
  static const brandPrimary = Color(0xFF6A4CFF);
  static const brandPrimaryDeep = Color(0xFF4F3BEF);
  static const brandViolet = Color(0xFF8B5CFF);
  static const brandPink = Color(0xFFF45DB3);
  static const brandGold = Color(0xFFFFD45C);
  static const brandCyan = Color(0xFF39D7E8);

  static const appBackground = Color(0xFFF8F6FF);
  static const appBackgroundAlt = Color(0xFFF1ECFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFBFAFF);
  static const surfaceLavender = Color(0xFFF3EFFF);

  static const textPrimary = Color(0xFF17163B);
  static const textSecondary = Color(0xFF6F6B8E);
  static const textMuted = Color(0xFF9A95B8);
  static const borderSoft = Color(0xFFEEE9FF);
  static const divider = Color(0xFFE7E1F7);

  static const success = Color(0xFF2ED47A);
  static const warning = Color(0xFFFFB547);
  static const error = Color(0xFFFF4D6D);
  static const info = Color(0xFF4DA3FF);

  static const darkBackground = Color(0xFF0F1024);
  static const darkSurface = Color(0xFF191A3A);
  static const darkCard = Color(0xFF202046);
  static const darkPrimary = Color(0xFF8B7CFF);
  static const darkPink = Color(0xFFFF6DB6);
  static const darkTextPrimary = Color(0xFFF7F4FF);
  static const darkTextSecondary = Color(0xFFC8C2E6);
  static const darkBorder = Color(0xFF34345D);
}
```

## 11A.4 Flutter widget build priority

Upgrade screens in this order:

1. App theme tokens
2. Shared cards/buttons/inputs/chips
3. Main app shell and bottom navigation
4. Home screen near-clone
5. Quick Capture bottom sheet
6. Tasks screens
7. Focus screens
8. Prayer screens
9. Profile/settings screens
10. Notes/habits/journal screens
11. AI/voice screens
12. Analytics/notifications/support screens
13. Loading/empty/error/offline states
14. Motion and micro-interactions

## 11A.5 Exact bottom navigation rule

The bottom navigation must contain exactly these tabs:

```text
Home | Tasks | Focus | Prayer | Profile
```

- Home icon: rounded home
- Tasks icon: checklist
- Focus icon: timer/target
- Prayer icon: crescent/mosque/prayer mat
- Profile icon: user/settings
- Active tab color: `brandPrimary`
- Inactive color: `textMuted`
- Active tab has small dot or soft pill indicator
- Floating add button is a separate quick-capture action, not a replacement for a tab

# 12. Full Screen List

## 12.1 Entry and authentication screens

1. Splash Screen
2. Welcome / Intro Screen
3. Sign In Screen
4. Sign Up Screen
5. Verify Email Screen
6. Forgot Password Screen
7. Reset Code Screen
8. New Password Screen
9. Password Reset Success Screen

## 12.2 Onboarding screens

10. Onboarding Start
11. Preferred Language
12. Country / City
13. Prayer Calculation Method
14. Main Goals
15. Wake-up Time
16. Sleep Time
17. Work / Study Hours
18. Notification Permission
19. Microphone Permission
20. Location Permission
21. Onboarding Summary
22. Personalization Complete

## 12.3 Main shell screens

23. Home Dashboard
24. Quick Capture Bottom Sheet
25. Voice Capture Flow
26. AI Parse Preview Bottom Sheet

## 12.4 Tasks screens

27. Tasks Main
28. Inbox Tasks
29. Today Tasks
30. Upcoming Tasks
31. Projects List
32. Project Details
33. Completed Tasks
34. Create Task
35. Edit Task
36. Task Details
37. Subtasks Editor
38. Task Reminder Setup
39. Task Recurrence Setup
40. Schedule / Calendar View

## 12.5 Notes screens

41. Notes Main
42. Notes Search
43. Note Editor
44. Checklist Note Editor
45. Voice Note Preview
46. Photo Note / Image Note
47. Note Details
48. Tags Manager
49. Archived Notes
50. Pinned Notes View

## 12.6 Habits screens

51. Habits Main
52. Create Habit
53. Edit Habit
54. Habit Details
55. Habit Log Calendar
56. Habit Analytics
57. Habit Reminder Setup

## 12.7 Focus screens

58. Focus Home
59. Active Focus Session
60. Focus Pause / Resume State
61. Session Complete
62. Break Timer
63. Focus History
64. Focus Settings

## 12.8 Prayer and spiritual screens

65. Prayer Home
66. Prayer Times
67. Prayer Tracking
68. Prayer History
69. Quran Goals
70. Quran Progress
71. Qibla Screen
72. Ramadan Mode
73. Athan Settings
74. Prayer Settings
75. Missed Prayer Tracking
76. Future Dhikr Reminders
77. Future Fasting Tracker
78. Future Islamic Calendar

## 12.9 Journal and reflection screens

79. Journal Main
80. Journal Editor
81. Mood Check-in
82. Gratitude Entry
83. Reflection Prompts
84. Journal Calendar
85. Journal Details
86. Future Weekly Life Review

## 12.10 AI and planning screens

87. AI Assistant Home
88. AI Chat
89. AI Task Parser Preview
90. AI Daily Plan Preview
91. AI Next Best Action
92. AI Schedule Suggestions
93. Future Goal Roadmap Generator
94. Future Study Planner AI
95. Future Motivation Engine
96. Future Time Context Recommendations

## 12.11 Analytics and insights screens

97. Analytics Overview
98. Productivity Analytics
99. Habit Analytics
100. Focus Analytics
101. Prayer Analytics
102. Weekly Summary
103. Calendar / Schedule Analytics

## 12.12 Notifications and reminders screens

104. Notification Center
105. Reminder Details
106. Reminder Settings
107. Task Reminder Flow
108. Habit Reminder Flow
109. Prayer Reminder Flow
110. Future Reminder Channels
111. Future Reminder QA / Reliability Gate

## 12.13 Profile and settings screens

112. Profile Home
113. Account Settings
114. Edit Profile
115. Appearance Settings
116. Language Settings
117. Notification Settings
118. Privacy & Data
119. Sync Status
120. Help & Support
121. Feedback
122. About App
123. Change Password
124. Sign Out Confirmation
125. Delete Account Confirmation

## 12.14 System states screens

126. Offline Mode Screen
127. Global Error Screen
128. Empty State Template
129. Loading Skeleton Template
130. Permission Explanation Template
131. Maintenance / Server Error Screen

---

# 13. Screen-by-Screen Design Specification and Google Stitch Prompts

---

## 13.1 Splash Screen

### Purpose

Initialize the app and show premium brand identity.

### Layout

- Full-screen soft lavender/off-white gradient.
- Center app icon, 92–110 px.
- App name under icon: “Smart Life Planner”.
- Tagline below: “Plan Smart. Live Better.”
- Subtle loading indicator near bottom.
- Optional soft orbit/sparkle animation around logo.

### Buttons

No buttons unless initialization fails.

### States

- Loading: logo animation + small loader.
- Error: show “Something went wrong” + Retry.
- No internet: continue if session/cache exists, otherwise show offline explanation.

### Stitch prompt

```text
Design a premium splash screen for Smart Life Planner. Use a soft light lavender gradient background, centered app logo, elegant app name typography, tagline “Plan Smart. Live Better.”, and a subtle calm loading animation. Match the same visual style as the uploaded App Preview: clean, rounded, premium, purple/pink accents, soft glow.
```

---

## 13.2 Welcome / Intro Screen

### Purpose

Explain app value and direct user to Sign In / Get Started.

### Layout

- Top: soft illustration showing dashboard cards, prayer moon, focus timer, notes, and AI sparkle.
- Middle: title.
- Body: 3 short benefit bullets.
- Bottom: primary and secondary buttons.

### Text

Title: “Organize your life with calm intelligence”  
Subtitle: “Tasks, habits, focus, prayer, notes, and AI planning in one beautiful system.”

Benefits:

- Capture everything quickly
- Plan your day with AI support
- Balance productivity with spiritual routines

### Buttons

- Primary: “Get Started”
- Secondary: “I already have an account”

### Placement

- Primary button at bottom, full width.
- Secondary below primary or text button under it.

### Stitch prompt

```text
Design the Welcome screen for Smart Life Planner. Use a premium light lavender background, a soft hero illustration of productivity + prayer + AI, a strong title, three elegant benefit rows, and bottom-aligned buttons: Get Started and I already have an account. Keep the same rounded, purple/pink, calm visual style as the App Preview.
```

---

## 13.3 Sign In Screen

### Purpose

Allow returning users to log in.

### Layout

- Top: small logo and “Welcome back”.
- Subtitle: “Continue your calm productive day.”
- Email field.
- Password field.
- Forgot password link.
- Primary button.
- Divider.
- Google sign-in button.
- Apple sign-in button if platform supports.
- Sign up link.

### Buttons

- Primary: “Sign In”
- Social: “Continue with Google”
- Optional: “Continue with Apple”
- Text link: “Forgot password?”
- Text link: “Create account”

### Placement

- Form centered vertically but slightly top-weighted.
- Buttons near lower half.
- Social buttons below divider.

### States

- Loading: button spinner.
- Error: inline field errors + top small error card.
- Success: button check state then navigate.
- No internet: banner and disable login if no cached auth.

### Stitch prompt

```text
Design a premium Sign In screen for Smart Life Planner. Use logo top, title “Welcome back”, clean rounded email and password fields, forgot password link, gradient Sign In button, social login buttons, and sign up link. Use soft card surfaces, light lavender background, and the same design language as the App Preview.
```

---

## 13.4 Sign Up Screen

### Purpose

Create new account.

### Layout

- Logo top.
- Title: “Create your life system”
- Fields:
  - Full name
  - Email
  - Password
  - Confirm password
- Terms checkbox.
- Primary button.
- Social sign-up buttons.
- Sign in link.

### Buttons

- “Create Account”
- “Continue with Google”
- “Continue with Apple”
- “Already have an account?”

### States

- Password mismatch.
- Weak password.
- Email already used.
- Loading/success.
- Verification required after signup.

### Stitch prompt

```text
Design a premium Sign Up screen for Smart Life Planner with rounded form fields, calm onboarding-style copy, gradient Create Account button, social sign-up buttons, and a sign-in link. Keep the design soft, spacious, trustworthy, and consistent with the App Preview.
```

---

## 13.5 Verify Email Screen

### Purpose

Verify account using code.

### Layout

- Top icon: mail/check.
- Title: “Verify your email”
- Subtitle with email.
- 6-digit code input boxes.
- Resend code timer.
- Primary button.

### Buttons

- “Verify”
- “Resend code”
- “Change email”

### Stitch prompt

```text
Design a Verify Email screen with a soft mail/check illustration, six rounded code boxes, resend code text, and a gradient Verify button. Use friendly validation states and keep it premium and calm.
```

---

## 13.6 Forgot Password / Reset Flow

### Screens

1. Forgot Password
2. Reset Code
3. New Password
4. Success

### Layout

Use the same form style as auth.

### Buttons

- “Send Reset Code”
- “Verify Code”
- “Set New Password”
- “Back to Sign In”

### Stitch prompt

```text
Design a 4-step password reset flow using the Smart Life Planner premium style. Include Forgot Password, Code Verification, New Password, and Success screens. Use rounded inputs, clear instructions, friendly validation, and bottom-aligned primary buttons.
```

---

# 14. Onboarding Screens

## 14.1 Onboarding Global Pattern

All onboarding screens should use:

- progress indicator at top
- back button top-left
- skip only for optional permission screens
- title
- subtitle
- large rounded selection cards
- bottom primary button
- soft background
- friendly illustrations

### Onboarding button placement

- Back icon: top-left, 44 px.
- Progress indicator: top center/right.
- Primary button: bottom full width.
- Secondary skip button: above primary or text link.

---

## 14.2 Onboarding Start

### Purpose

Introduce personalization.

### Layout

- Hero illustration: mini dashboard forming around user.
- Title: “Let’s personalize your life system”
- Subtitle: “A few choices help Smart Life Planner build your dashboard, prayer schedule, habits, and AI suggestions.”
- Button: “Start Setup”

### Stitch prompt

```text
Design an onboarding start screen for Smart Life Planner. Show a friendly premium illustration of dashboard cards forming around the user. Use title “Let’s personalize your life system”, short subtitle, and bottom gradient button “Start Setup”.
```

---

## 14.3 Preferred Language Screen

### Options

- English
- العربية

### Layout

- Two large language cards.
- Each card has icon/flag/text.
- Selected card has gradient border and checkmark.

### Buttons

- Continue
- Back

### RTL note

Arabic selection should preview RTL support.

### Stitch prompt

```text
Design the Preferred Language onboarding screen with two large rounded cards: English and العربية. Use selected-card gradient outline, checkmark, clear typography, progress indicator, and bottom Continue button.
```

---

## 14.4 Country / City Screen

### Purpose

Set location for prayer times and timezone.

### Layout

- Search field at top.
- Current location suggestion card.
- Popular cities list.
- Manual city selection.
- Permission explanation card.

### Buttons

- “Use Current Location”
- “Continue”
- “Enter Manually”

### Stitch prompt

```text
Design a Country/City onboarding screen. Include a rounded search field, current location card, popular city list, manual entry option, and bottom Continue button. Keep it clean, privacy-respectful, and visually consistent with the App Preview.
```

---

## 14.5 Prayer Calculation Method Screen

### Options

- Egyptian General Authority
- Muslim World League
- Umm al-Qura
- Custom / Advanced

### Layout

- Explanation card.
- Method cards with short descriptions.
- Recommended badge for user region.

### Buttons

- Continue
- Learn More

### Stitch prompt

```text
Design a Prayer Calculation Method onboarding screen with elegant method selection cards, recommended badge, short explanations, and a bottom Continue button. Use spiritual but modern styling.
```

---

## 14.6 Main Goals Screen

### Options

Multi-select cards:

- Study
- Work
- Self improvement
- Fitness
- Spiritual growth
- Better focus
- Better habits
- Reduce overwhelm
- AI planning

### Layout

- 2-column goal cards.
- Each card has icon, title, small text.
- Selected cards show checkmark.

### Button

- “Continue”

### Stitch prompt

```text
Design the Main Goals onboarding screen. Use a two-column grid of rounded selectable cards for Study, Work, Self improvement, Fitness, Spiritual growth, Better focus, Better habits, Reduce overwhelm, and AI planning. Use selected checkmarks and a bottom Continue button.
```

---

## 14.7 Wake-up Time Screen

### Layout

- Large time picker card.
- Recommended routine tips.
- Optional “I don’t have fixed wake time”.

### Button

- Continue

### Stitch prompt

```text
Design a Wake-up Time onboarding screen with a large premium time picker card, soft gradient highlight, small routine tip card, and bottom Continue button.
```

---

## 14.8 Sleep Time Screen

Similar to Wake-up Time.

### Stitch prompt

```text
Design a Sleep Time onboarding screen with a calm night-style soft lavender card, time picker, healthy routine tip, and bottom Continue button. Keep it consistent with the light premium style.
```

---

## 14.9 Work / Study Hours Screen

### Layout

- Day schedule mini timeline.
- Start time and end time selectors.
- Toggle: “Different schedule on weekends”.

### Buttons

- Continue
- Skip for now

### Stitch prompt

```text
Design a Work/Study Hours onboarding screen with a mini daily timeline, start/end time selectors, weekend toggle, and bottom Continue button. Make it clean, practical, and premium.
```

---

## 14.10 Notification Permission Screen

### Layout

- Bell illustration.
- Explanation of reminders.
- Permission examples:
  - task reminders
  - habit reminders
  - prayer reminders
  - focus session alerts

### Buttons

- “Enable Notifications”
- “Not now”

### Stitch prompt

```text
Design a Notification Permission onboarding screen with a bell illustration, reminder examples, and buttons Enable Notifications and Not now. Make the screen trustworthy and non-pushy.
```

---

## 14.11 Microphone Permission Screen

### Purpose

Voice capture.

### Layout

- Microphone illustration.
- Explanation: Arabic/English voice capture.
- Privacy note.

### Buttons

- “Enable Voice Capture”
- “Not now”

### Stitch prompt

```text
Design a Microphone Permission onboarding screen for voice task/note capture. Include microphone illustration, Arabic/English support note, privacy reassurance, and buttons Enable Voice Capture and Not now.
```

---

## 14.12 Location Permission Screen

### Purpose

Prayer times + Qibla.

### Layout

- Location/prayer illustration.
- Explanation.
- Manual city fallback.

### Buttons

- “Allow Location”
- “Use Manual City”

### Stitch prompt

```text
Design a Location Permission onboarding screen explaining that location improves prayer times and Qibla. Include Allow Location and Use Manual City buttons. Keep it respectful, simple, and privacy-aware.
```

---

## 14.13 Onboarding Summary Screen

### Layout

- Summary cards:
  - language
  - city
  - prayer method
  - goals
  - wake/sleep time
  - permissions
- Edit icons on each card.
- Button: “Build My Dashboard”

### Stitch prompt

```text
Design an Onboarding Summary screen with stacked rounded summary cards for language, city, prayer method, goals, routine, and permissions. Each card has an edit icon. Bottom button says Build My Dashboard.
```

---

## 14.14 Personalization Complete Screen

### Layout

- Success check animation.
- Title: “Your dashboard is ready”
- Subtitle: “We created your first life system.”
- Button: “Go to Home”

### Stitch prompt

```text
Design a Personalization Complete screen with a premium success check animation, soft dashboard preview, title “Your dashboard is ready”, and button “Go to Home”.
```

---

# 15. Main App Shell

## 15.1 Shell layout

The main app shell contains:

- screen content
- floating bottom navigation
- center plus button
- preserved state per tab

## 15.2 Bottom navigation design

Placement:

- bottom 16 px from screen edge
- left/right margin 20 px
- height 78–86 px
- radius 30 px
- white translucent surface
- soft shadow
- center plus button raised

Tabs:

1. Home
2. Tasks
3. Focus
4. Prayer
5. Profile

### Stitch prompt

```text
Design the Smart Life Planner main app shell with a floating premium bottom navigation bar. Tabs: Home, Tasks, Focus, Prayer, Profile. Add a raised center plus button for Quick Capture. Use the same style as the App Preview bottom dock: rounded, white, soft shadow, purple active state, muted inactive icons.
```

---

# 16. Home Dashboard — MASTER SCREEN

## 16.1 Critical instruction

The Home Dashboard must be a **near-clone of the uploaded App Preview image**.

Do not simplify it.  
Do not change its card hierarchy.  
Do not create a generic dashboard.  
Use the App Preview as master reference.

## 16.2 Screen structure

Order:

1. Status bar / safe area
2. Header row
3. Daily summary gradient card
4. Two-card row:
   - Next Prayer
   - Focus Session
5. Today’s Tasks card
6. Bottom row:
   - Habits Overview
   - AI Suggestion
7. Floating bottom navigation

## 16.3 Header

### Placement

- Top under safe area.
- Horizontal row.
- Padding 20 px.
- Height 58–66 px.

### Elements

Left:

- App icon 48 × 48 px.
- Rounded square.
- Purple/pink gradient.
- Use Smart Life Planner logo.

Middle:

- Greeting: “Good Morning, Mahmoud ☀️”
- Date: “Tue, Apr 15 · 7 Shawwal 1446”

Right:

- notification circle button 44 px.
- avatar circle 44 px.

### Stitch prompt

```text
Design the Home header exactly like the App Preview: app icon on the left, greeting “Good Morning, Mahmoud ☀️”, date under it, notification circle button with red dot, and circular avatar on the right. Use clean bold typography and soft spacing.
```

## 16.4 Daily Summary Card

### Placement

- Full width.
- Top margin 18–22 px from header.
- Height 175–185 px.
- Radius 28–30 px.

### Visual

- Purple-to-pink gradient.
- Subtle sparkles.
- Faint chart bars.
- Glossy soft glow.

### Text

Title:

- “Today looks balanced”
- “balanced” in warm gold.

Subtitle:

- “Keep going! You’re building consistency that matters.”

Button:

- “View your day”
- white pill
- purple text
- right arrow

Right:

- Circular progress ring.
- “72%”
- “Day Progress”

### Stitch prompt

```text
Create the main Home summary card as a near-match to the App Preview. Full-width rounded gradient card, purple/violet/pink background, title “Today looks balanced” with balanced highlighted in gold, subtitle, white “View your day” pill button, and right-side circular progress ring with “72% Day Progress”. Add subtle sparkles and faint chart bars.
```

## 16.5 Next Prayer Card

### Placement

- Left half card.
- Under summary card.
- Height about 210 px.
- Radius 26–28 px.

### Content

- Header: crescent icon + “Next Prayer”
- Prayer: “Dhuhr”
- Time: “12:15 PM”
- Countdown: “in 2h 34m”
- Mosque illustration lower-right.
- Button: “View Prayer Times”

### Stitch prompt

```text
Design the Next Prayer card exactly like the App Preview style. White rounded card, crescent icon, label “Next Prayer”, large Dhuhr 12:15 PM, countdown, subtle mosque illustration in lower-right, and bottom-left white pill button “View Prayer Times”.
```

## 16.6 Focus Session Card

### Placement

- Right half card.
- Same height as Prayer card.

### Content

- Header: focus icon + “Focus Session”
- Circular timer: “25:00”
- Small label: “Focus Time”
- Gradient ring.
- Button: “Start Focus” with play icon.

### Stitch prompt

```text
Design the Focus Session card as in the App Preview: white rounded card, focus icon and title, center circular 25:00 timer with purple-pink gradient ring, and bottom gradient Start Focus button with play icon.
```

## 16.7 Today’s Tasks Card

### Placement

- Full width.
- Under prayer/focus row.
- Height around 245–260 px.
- Radius 28 px.

### Header

- clipboard icon
- “Today’s Tasks”
- “View all” right link

### Rows

1. Complete research report
   - Work · High Priority
   - badge: In Progress
   - progress: 60%

2. Workout at the gym
   - Health · Build Strength
   - badge: Today
   - check circle

3. Study half Juz of Quran
   - Spiritual · Learn & Reflect
   - badge: Today
   - check circle

### Stitch prompt

```text
Design the Today’s Tasks card to match the App Preview. Full-width white rounded card, header with clipboard icon, title, View all link, and 3 rounded task rows with icon bubbles, title, subtitle, status pill, progress/check indicator. Use premium spacing and soft borders.
```

## 16.8 Habits Overview Card

### Placement

- Bottom left small card.
- Height 145–155 px.
- Radius 26 px.

### Content

- Header: chart icon + “Habits Overview” + three dots.
- Circular streak ring with “7 Day Streak”.
- Completed 5/7.
- Progress bar.
- “This Week”.

### Stitch prompt

```text
Design the Habits Overview card like the App Preview: small white rounded card, chart icon, title, three dots menu, circular streak ring with 7 Day Streak, completed 5/7, and weekly progress bar.
```

## 16.9 AI Suggestion Card

### Placement

- Bottom right small card.
- Same height as habits card.

### Content

- Header: sparkle icon + “AI Suggestion”
- Quote:
  “Small steps today create big changes tomorrow. You’ve got this!”
- CTA: “Ask AI anything”
- Cute small robot illustration on right.

### Stitch prompt

```text
Design the AI Suggestion card like the App Preview: white rounded card, sparkle icon, title, supportive short message, “Ask AI anything” link, and cute small white/purple robot illustration on the right with soft glow.
```

## 16.10 Home screen full prompt

```text
Design the Smart Life Planner Home screen as a near-clone of the uploaded App Preview image. Keep the exact screen order: header, gradient progress summary card, Next Prayer card, Focus Session card, Today’s Tasks card, Habits Overview card, AI Suggestion card, and floating bottom navigation. Match the same soft lavender background, rounded white cards, purple/pink gradients, gold highlight, soft shadows, premium spacing, and clean typography. The screen must feel like a polished Flutter-ready mobile dashboard for productivity, prayer, focus, habits, tasks, and AI planning.
```

---

# 17. Quick Capture Bottom Sheet

## Purpose

Fastest way to add anything.

## Layout

- Bottom sheet height 70–90% depending content.
- Drag handle.
- Title: “Quick Capture”
- Input field: “Type or speak what’s on your mind…”
- Action chips:
  - Task
  - Note
  - Reminder
  - Habit
  - Voice
  - Ask AI
- AI parse preview area.
- Primary button: “Save”
- Secondary: “Preview with AI”

## Placement

- Input near top.
- Chips immediately below.
- Primary button sticky at bottom.

## Stitch prompt

```text
Design a premium Quick Capture bottom sheet for Smart Life Planner. Include a drag handle, title, large rounded input, chips for Task, Note, Reminder, Habit, Voice, and Ask AI, plus bottom buttons Save and Preview with AI. Use the same light premium style and gradient primary action.
```

---

# 18. Tasks Screens

## 18.1 Tasks Main

### Purpose

Full task management center.

### Layout

- Header: “Tasks”
- Search icon and filter icon top-right.
- Segmented tabs:
  - Inbox
  - Today
  - Upcoming
  - Projects
  - Completed
- Smart filter chips below.
- Task list.
- Floating add task button.

### Buttons

- Add task
- Search
- Filter
- Sort
- View calendar
- AI plan

### Stitch prompt

```text
Design the Tasks Main screen for Smart Life Planner inspired by TickTick clarity but in the App Preview style. Include header, search/filter icons, segmented tabs for Inbox/Today/Upcoming/Projects/Completed, smart filter chips, rounded task cards, and a floating Add Task button. Use soft lavender background and premium white cards.
```

## 18.2 Inbox Tasks

### Layout

- Header: “Inbox”
- Short helper text: “Clarify captured tasks.”
- List of unorganized tasks.
- Each card has classify button.
- Empty state if none.

### Buttons

- Clarify
- Move to project
- Set date
- Delete
- Add task

### Stitch prompt

```text
Design an Inbox Tasks screen with a clean list of captured tasks waiting for clarification. Each task card should have quick actions: Clarify, Set date, Move, Delete. Include a friendly empty state.
```

## 18.3 Today Tasks

### Layout

- Header: “Today”
- Day progress card.
- Time sections:
  - Morning
  - Afternoon
  - Evening
- Task cards grouped by time.
- Prayer markers in day timeline.

### Buttons

- Add task
- Start focus
- Reschedule
- Complete

### Stitch prompt

```text
Design a Today Tasks screen with a daily progress card, time-grouped task list, prayer time markers, and quick actions. Make it feel like a calm daily execution screen with premium rounded cards.
```

## 18.4 Upcoming Tasks

### Layout

- Calendar strip at top.
- Upcoming grouped by date.
- Filter chips for week/month/priority.

### Buttons

- Calendar view
- Filter
- Add deadline

### Stitch prompt

```text
Design an Upcoming Tasks screen with a horizontal calendar strip, grouped upcoming task cards by date, filter chips, and clear deadline badges. Use premium soft cards and purple accents.
```

## 18.5 Projects List

### Layout

- Header: “Projects”
- Search.
- Project cards:
  - project name
  - progress
  - deadline
  - task count
  - color/icon
- Add project button.

### Stitch prompt

```text
Design a Projects screen with rounded project cards showing project name, progress ring/bar, deadline, and task count. Include search and Add Project button. Keep it clean like Notion blocks but styled like the App Preview.
```

## 18.6 Project Details

### Layout

- Header with project title.
- Progress summary card.
- Task sections:
  - Next actions
  - In progress
  - Completed
- Notes linked to project.
- AI breakdown suggestion card.

### Buttons

- Add task
- Edit project
- Add note
- AI break down project

### Stitch prompt

```text
Design a Project Details screen with a premium project summary card, progress, next actions, task sections, linked notes, and AI breakdown suggestion card. Use structured Notion-like blocks with rounded Smart Life Planner styling.
```

## 18.7 Create/Edit Task

### Layout

- Modal screen or bottom sheet.
- Title field top.
- Description.
- Due date/time.
- Priority.
- Project.
- Reminder.
- Recurrence.
- Estimated duration.
- Difficulty.
- Energy.
- Dependencies.
- Save button sticky bottom.

### Buttons

- Save Task
- Cancel
- Add subtask
- Add reminder
- Add recurrence
- AI improve

### Stitch prompt

```text
Design a Create/Edit Task screen with a large title input, description, due date, priority, project, reminder, recurrence, estimated duration, difficulty, energy, dependencies, and sticky bottom Save Task button. Keep the form calm, clean, and easy for beginners.
```

## 18.8 Task Details

### Layout

- Header with back, more.
- Task title.
- Status/progress.
- Metadata chips.
- Subtasks checklist.
- Notes/comments.
- Reminder card.
- AI next-action suggestion.

### Buttons

- Complete
- Start Focus
- Edit
- Delete
- Add subtask
- Add note
- Reschedule

### Stitch prompt

```text
Design a Task Details screen with title, status, metadata chips, subtasks checklist, reminder card, notes section, and bottom actions Complete and Start Focus. Use premium white cards and gentle purple accents.
```

## 18.9 Schedule / Calendar View

### Layout

- Header: “Schedule”
- Day/week toggle.
- Timeline with time slots.
- Task blocks.
- Focus blocks.
- Prayer time markers.
- AI suggested blocks with sparkle.

### Buttons

- Add block
- Replan
- Lock block
- Edit block

### Stitch prompt

```text
Design a Schedule/Calendar screen with a clean timeline, task blocks, focus blocks, prayer markers, and AI-suggested blocks. Use soft rounded cards and a calm productivity layout inspired by premium calendar apps.
```

---

# 19. Notes Screens

## 19.1 Notes Main

### Layout

- Header: “Notes”
- Search bar.
- Filter chips:
  - All
  - Pinned
  - Checklists
  - Voice
  - Images
  - Archived
- Masonry/grid note cards.
- Floating add note button.

### Buttons

- Add note
- Search
- Filter
- Pin
- Archive
- Tags

### Stitch prompt

```text
Design a Notes Main screen inspired by Google Keep but premium. Use a masonry grid of rounded note cards, search bar, filter chips, pinned section, add note floating button, and soft pastel note card accents. Keep the Smart Life Planner App Preview style.
```

## 19.2 Note Editor

### Layout

- Top bar: back, pin, reminder, more.
- Title input.
- Body editor.
- Tags row.
- Attachments section.
- Bottom toolbar:
  - checklist
  - image
  - voice
  - color
  - AI summarize
  - extract task

### Buttons

- Save
- Pin
- Add reminder
- Add tag
- Add image
- Record voice
- AI summarize
- Extract actions

### Stitch prompt

```text
Design a premium Note Editor screen with title input, body editor, tags, attachments, and bottom toolbar for checklist, image, voice, color, AI summarize, and extract task. Use clean Notion/Keep-inspired structure but with the Smart Life Planner visual style.
```

## 19.3 Checklist Note Editor

### Layout

- Title.
- Checklist items.
- Add item row.
- Completed items collapsible.
- Reminder/tag controls.

### Stitch prompt

```text
Design a Checklist Note Editor with clean rounded checklist rows, add item field, completed items section, tags/reminder controls, and soft premium note styling.
```

## 19.4 Voice Note Preview

### Layout

- Waveform card.
- Transcript area.
- Edit transcript.
- Save as note / extract task.

### Buttons

- Play
- Re-record
- Save note
- Extract tasks

### Stitch prompt

```text
Design a Voice Note Preview screen with waveform card, transcript preview, edit transcript option, play/re-record controls, and buttons Save Note and Extract Tasks.
```

## 19.5 Tags Manager

### Layout

- List of tags.
- Add tag field.
- Color selector.
- Note count per tag.

### Stitch prompt

```text
Design a Tags Manager screen with rounded tag rows, add tag field, color dots, note counts, and edit/delete actions. Keep it minimal and premium.
```

---

# 20. Habits Screens

## 20.1 Habits Main

### Layout

- Header: “Habits”
- Daily habit progress card.
- Habit cards grouped:
  - Morning
  - Afternoon
  - Evening
- Streak badges.
- Add habit button.

### Buttons

- Add habit
- Mark done
- Skip today
- View analytics
- Edit habit

### Stitch prompt

```text
Design a Habits Main screen with daily progress summary, grouped habit cards, streak badges, mark-done circles, and Add Habit button. Keep it motivating, calm, and premium.
```

## 20.2 Create/Edit Habit

### Fields

- Habit name
- Icon
- Color
- Frequency
- Reminder time
- Goal
- Category
- Start date

### Buttons

- Save Habit
- Cancel

### Stitch prompt

```text
Design a Create/Edit Habit screen with habit name, icon/color selector, frequency selector, reminder time, goal, category, and bottom Save Habit button. Use friendly rounded form components.
```

## 20.3 Habit Details

### Layout

- Header.
- Streak hero card.
- Calendar grid.
- Weekly completion chart.
- Reminder card.
- Notes/reflection.

### Buttons

- Mark today
- Edit
- Pause habit
- Delete

### Stitch prompt

```text
Design a Habit Details screen with streak hero card, completion calendar grid, weekly progress chart, reminder card, and actions Mark Today, Edit, Pause. Use purple/pink progress rings and soft white cards.
```

---

# 21. Focus Screens

## 21.1 Focus Home

### Layout

- Header: “Focus”
- Main timer card.
- Focus mode presets:
  - 25/5 Pomodoro
  - Deep Work
  - Study
  - Custom
- Today focus stats.
- Recent sessions.
- Start button.

### Buttons

- Start Focus
- Choose preset
- Custom timer
- View history
- Settings

### Stitch prompt

```text
Design the Focus Home screen inspired by Focus To-Do but in Smart Life Planner style. Include a large timer card, focus presets, today stats, recent sessions, and a prominent Start Focus button.
```

## 21.2 Active Focus Session

### Layout

- Full-screen calm mode.
- Large circular timer.
- Task title if linked.
- Prayer-aware upcoming reminder if needed.
- Pause/Stop buttons.
- Ambient background.

### Buttons

- Pause
- Stop
- Finish early
- Add note
- Lock distraction mode toggle

### Stitch prompt

```text
Design an Active Focus Session screen with a large circular 25:00 timer, calming lavender background, linked task title, pause/stop buttons, subtle progress animation, and minimal distractions.
```

## 21.3 Session Complete

### Layout

- Success animation.
- Session summary:
  - focus duration
  - task
  - streak
- Reflection input.
- Next action suggestion.

### Buttons

- Start Break
- Start Another
- Save Session
- Back Home

### Stitch prompt

```text
Design a Session Complete screen with a premium success animation, focus summary, streak badge, reflection input, and buttons Start Break, Start Another, Save Session, and Back Home.
```

## 21.4 Focus History

### Layout

- Stats cards.
- Weekly bar chart.
- Session list.
- Filter by week/month.

### Stitch prompt

```text
Design a Focus History screen with weekly focus stats, bar chart, session list, and filters. Use premium rounded analytics cards.
```

---

# 22. Prayer and Spiritual Screens

## 22.1 Prayer Home

### Layout

- Header: “Prayer”
- Next prayer hero card.
- All prayer times list.
- Prayer tracking row.
- Quran goal card.
- Qibla shortcut.
- Ramadan mode shortcut.
- Settings icon.

### Buttons

- Mark as prayed
- View all times
- Open Qibla
- Quran goal
- Ramadan mode
- Settings

### Stitch prompt

```text
Design the Prayer Home screen with a next prayer hero card, daily prayer times list, prayer tracking check row, Quran goal card, Qibla shortcut, and Ramadan mode shortcut. Use a modern spiritual style, not old-fashioned, with the same purple/pink premium design language.
```

## 22.2 Prayer Times

### Layout

- Date selector.
- List:
  - Fajr
  - Sunrise
  - Dhuhr
  - Asr
  - Maghrib
  - Isha
- Each row has time, notification toggle, status.
- Current/next prayer highlighted.

### Stitch prompt

```text
Design a Prayer Times screen with date selector and elegant prayer time rows. Highlight the next prayer, include notification toggles, and use soft spiritual icons.
```

## 22.3 Prayer Tracking

### Layout

- Daily five-prayer checklist.
- Completion progress ring.
- Missed prayer notes if applicable.
- Weekly mini chart.

### Buttons

- Mark complete
- Undo
- View history

### Stitch prompt

```text
Design a Prayer Tracking screen with five prayer checklist cards, completion progress ring, weekly mini chart, and mark/undo actions. Keep it respectful, calm, and visually consistent.
```

## 22.4 Prayer History

### Layout

- Calendar heatmap.
- Weekly/monthly consistency stats.
- Prayer-specific breakdown.

### Stitch prompt

```text
Design a Prayer History screen with calendar heatmap, weekly/monthly consistency stats, and prayer-specific breakdown cards. Use gentle spiritual visuals and premium analytics cards.
```

## 22.5 Quran Goals

### Layout

- Current goal card.
- Daily pages/juz progress.
- Streak.
- Add reading log.
- Goal settings.

### Buttons

- Log reading
- Edit goal
- View progress

### Stitch prompt

```text
Design a Quran Goals screen with current Quran goal card, daily progress, streak, reading log button, and progress history. Use respectful book iconography and soft purple/gold accents.
```

## 22.6 Qibla Screen

### Layout

- Large compass card.
- Direction arrow.
- Numeric bearing.
- Location status.
- Calibration message.
- Manual location fallback.

### Buttons

- Refresh location
- Set manual location
- Calibration help

### Stitch prompt

```text
Design a Qibla screen with a large premium compass card, Qibla direction arrow, numeric bearing, location status, and manual location fallback. Use a clean modern spiritual style.
```

## 22.7 Ramadan Mode

### Layout

- Ramadan mode toggle hero.
- Today fasting status.
- Fajr/Suhoor card.
- Maghrib/Iftar card.
- Taraweeh tracking toggle.
- Fasting tracker shortcut.

### Buttons

- Enable Ramadan Mode
- Set Suhoor reminder
- Set Iftar reminder
- Log fast

### Stitch prompt

```text
Design a Ramadan Mode screen with a hero toggle, Fajr/Suhoor and Maghrib/Iftar cards, reminder settings, fasting status, and Taraweeh tracking. Keep it modern, respectful, and clean.
```

## 22.8 Prayer Settings

### Fields

- city/location
- calculation method
- madhab/asr method
- notification offsets
- Athan sound
- silent mode during prayer
- manual adjustments

### Buttons

- Save
- Reset defaults

### Stitch prompt

```text
Design a Prayer Settings screen with grouped settings cards for location, calculation method, Asr method, notification offsets, Athan sound, silent mode, and manual adjustments. Use clean grouped settings styling.
```

---

# 23. Journal and Reflection Screens

## 23.1 Journal Main

### Layout

- Header: “Journal”
- Mood check-in card.
- Today reflection prompt.
- Recent entries.
- Calendar strip.

### Buttons

- New Entry
- Mood Check-in
- Gratitude
- Search

### Stitch prompt

```text
Design a Journal Main screen with mood check-in card, daily reflection prompt, recent entries, and calendar strip. Use calm soft surfaces and emotional clarity.
```

## 23.2 Journal Editor

### Layout

- Date at top.
- Mood selector.
- Prompt card.
- Text area.
- Gratitude chips.
- Save button.

### Buttons

- Save Entry
- Add gratitude
- Add voice
- AI reflection helper

### Stitch prompt

```text
Design a Journal Editor with mood selector, prompt card, large writing area, gratitude chips, and Save Entry button. Keep it private, calm, and distraction-free.
```

## 23.3 Mood Check-in

### Layout

- Emoji/mood cards.
- Energy slider.
- Stress slider.
- Short note field.

### Stitch prompt

```text
Design a Mood Check-in screen with large mood cards, energy and stress sliders, optional note field, and bottom Save button. Use soft friendly visuals.
```

---

# 24. AI Assistant and Planning Screens

## 24.1 AI Assistant Home

### Layout

- Header: “AI Assistant”
- Friendly robot/avatar.
- Prompt input.
- Suggested prompt chips:
  - Plan my day
  - Break down a task
  - What should I do next?
  - Summarize my week
  - Create study plan
- Recent AI actions.

### Buttons

- Send
- Voice input
- New chat
- Prompt chips

### Stitch prompt

```text
Design an AI Assistant Home screen with friendly robot visual, prompt input, suggested action chips, and recent AI actions. Use the same premium purple/pink style, with AI feeling helpful and safe.
```

## 24.2 AI Chat

### Layout

- Chat messages.
- User messages right.
- AI messages left.
- Structured cards for suggested actions.
- Input bar bottom.
- Voice button.

### Buttons

- Send
- Voice
- Apply after review
- Edit suggestion
- Dismiss

### Stitch prompt

```text
Design an AI Chat screen for Smart Life Planner. Use clean message bubbles, structured suggestion cards, input bar, voice button, and clear Apply after review buttons. AI must feel controlled and trustworthy.
```

## 24.3 AI Task Parser Preview

### Layout

- Original input at top.
- Parsed structured fields:
  - title
  - due date
  - priority
  - project
  - reminder
  - subtasks
- Editable fields.
- Confirm button.

### Buttons

- Save Task
- Edit
- Convert to note
- Cancel

### Stitch prompt

```text
Design an AI Task Parser Preview screen/bottom sheet. Show original user input, parsed task fields as editable cards, and bottom actions Save Task, Edit, Convert to Note, and Cancel. Make it clear AI is suggesting, not forcing.
```

## 24.4 AI Daily Plan Preview

### Layout

- Day plan timeline.
- Task blocks.
- Focus blocks.
- Prayer windows.
- Warnings for overload.
- Explanation card.

### Buttons

- Accept Plan
- Edit Plan
- Regenerate
- Lock block

### Stitch prompt

```text
Design an AI Daily Plan Preview screen with a timeline, task blocks, focus blocks, prayer windows, overload warning if needed, and explanation card. Include Accept Plan, Edit Plan, and Regenerate buttons. Keep it calm and transparent.
```

## 24.5 Next Best Action

### Layout

- Hero card: “Recommended next”
- Task title.
- Why this task.
- Energy/time fit.
- Prayer/focus context.
- Start action.

### Buttons

- Start Focus
- Mark done
- Skip
- Explain more

### Stitch prompt

```text
Design a Next Best Action screen/card showing the recommended task, why it was chosen, time/energy fit, and actions Start Focus, Mark Done, Skip, Explain More. Use AI sparkle accents but keep it practical.
```

---

# 25. Voice Capture Flow

## 25.1 Voice Recording

### Layout

- Large microphone orb.
- Waveform animation.
- Language indicator: English / Arabic / Auto.
- Cancel button.
- Stop button.

### Buttons

- Start recording
- Stop
- Cancel
- Change language

### Stitch prompt

```text
Design a Voice Capture screen with a large glowing microphone orb, waveform animation, language selector for English/Arabic/Auto, and Stop/Cancel buttons. Keep it premium and clear.
```

## 25.2 Voice Transcript Preview

### Layout

- Transcript card.
- Confidence indicator.
- Editable text.
- AI detected intent.
- Confirm action.

### Buttons

- Save as task
- Save as note
- Try again
- Edit transcript

### Stitch prompt

```text
Design a Voice Transcript Preview screen with transcript card, confidence indicator, editable text, detected intent, and buttons Save as Task, Save as Note, Try Again, and Edit Transcript.
```

---

# 26. Analytics Screens

## 26.1 Analytics Overview

### Layout

- Header: “Analytics”
- Date range selector.
- Summary cards:
  - tasks completed
  - focus minutes
  - habits completed
  - prayer consistency
- Trend charts.
- Insight cards.

### Buttons

- Change range
- View details
- Export optional

### Stitch prompt

```text
Design an Analytics Overview screen with date range selector, four summary cards, trend charts, and insight cards. Use premium dashboard visuals consistent with the Home screen.
```

## 26.2 Productivity Analytics

### Layout

- Task completion chart.
- Deadline risk stats.
- Focus time correlation.
- Best productivity time.

### Stitch prompt

```text
Design a Productivity Analytics screen with task completion charts, deadline risk cards, best productivity time insight, and focus correlation. Use clean premium charts.
```

## 26.3 Habit Analytics

### Layout

- Habit streaks.
- Completion heatmap.
- Weekly/monthly progress.

### Stitch prompt

```text
Design a Habit Analytics screen with streak cards, completion heatmap, weekly/monthly progress, and supportive insight cards.
```

## 26.4 Prayer Analytics

### Layout

- Prayer consistency card.
- Weekly completion.
- Prayer-by-prayer breakdown.
- Gentle motivational insight.

### Stitch prompt

```text
Design a Prayer Analytics screen with prayer consistency card, weekly completion chart, prayer-by-prayer breakdown, and respectful supportive insight.
```

---

# 27. Notifications and Reminders Screens

## 27.1 Notification Center

### Layout

- Header: “Notifications”
- Tabs:
  - All
  - Tasks
  - Habits
  - Prayer
  - AI
- Notification cards grouped by date.
- Mark all read.

### Buttons

- Mark all read
- Open item
- Snooze
- Dismiss

### Stitch prompt

```text
Design a Notification Center with grouped notification cards, tabs for All/Tasks/Habits/Prayer/AI, mark all read action, and swipe actions for Snooze and Dismiss.
```

## 27.2 Reminder Settings

### Layout

- Global reminder preferences.
- Channels:
  - local/push
  - email future
  - in-app
- Quiet hours.
- Snooze defaults.
- Prayer reminder offsets.

### Stitch prompt

```text
Design a Reminder Settings screen with grouped cards for channels, quiet hours, snooze defaults, prayer offsets, task/habit reminders, and clear toggles. Use clean settings design.
```

## 27.3 Reminder Details

### Layout

- Reminder title.
- Source item.
- Time.
- Repeat rule.
- Channel.
- Snooze options.

### Buttons

- Save
- Snooze
- Delete
- Open source item

### Stitch prompt

```text
Design a Reminder Details screen with source item, time, recurrence, channel, snooze options, and actions Save, Snooze, Delete, Open Source.
```

---

# 28. Profile and Settings Screens

## 28.1 Profile Home

### Layout

- Profile hero card:
  - avatar
  - name
  - email
  - streak/level optional
- Settings list:
  - Account
  - Appearance
  - Language
  - Notifications
  - Prayer Preferences
  - Focus Preferences
  - Analytics
  - Privacy & Data
  - Help & Support
  - About
- Sign out button at bottom.

### Stitch prompt

```text
Design a Profile Home screen with profile hero card, avatar, name/email, and grouped settings list. Include Account, Appearance, Language, Notifications, Prayer Preferences, Focus Preferences, Analytics, Privacy & Data, Help & Support, About, and Sign Out. Keep it clean and premium.
```

## 28.2 Account Settings

### Layout

- Name
- Email
- Provider
- Verification status
- Change password
- Linked accounts
- Delete account

### Stitch prompt

```text
Design an Account Settings screen with editable name/email, provider, verification status, change password, linked accounts, and delete account section. Use safe destructive styling.
```

## 28.3 Appearance Settings

### Layout

- Theme mode:
  - System
  - Light
  - Dark
- Accent color future.
- App icon preview.
- UI density future.

### Stitch prompt

```text
Design an Appearance Settings screen with theme mode cards, accent color placeholder, app icon preview, and clean grouped settings.
```

## 28.4 Language Settings

### Layout

- English
- Arabic
- RTL preview card.

### Stitch prompt

```text
Design a Language Settings screen with English and Arabic selection cards, selected state, RTL preview card, and Save button.
```

## 28.5 Notification Settings

### Layout

- Master toggle.
- Task reminders.
- Habit reminders.
- Prayer notifications.
- Focus alerts.
- AI suggestions.
- Quiet hours.

### Stitch prompt

```text
Design a Notification Settings screen with grouped toggles for tasks, habits, prayer, focus, AI suggestions, and quiet hours. Use calm clean settings cards.
```

## 28.6 Privacy & Data

### Layout

- Data sync status.
- Export data.
- Delete data.
- AI privacy controls.
- Location storage explanation.
- Voice data explanation.

### Stitch prompt

```text
Design a Privacy & Data screen with sync status, export data, delete data, AI privacy controls, location privacy, and voice privacy explanations. Make it trustworthy and clear.
```

## 28.7 Help & Support

### Layout

- Search help.
- FAQ cards.
- Contact support.
- Send feedback.
- Report bug.

### Stitch prompt

```text
Design a Help & Support screen with FAQ cards, search, contact support, send feedback, and report bug actions. Use friendly support styling.
```

## 28.8 About App

### Layout

- Logo.
- App name.
- Version.
- Mission statement.
- Links:
  - terms
  - privacy
  - licenses

### Stitch prompt

```text
Design an About App screen with logo, app name, version, mission statement, and links to Terms, Privacy, and Licenses. Keep it premium and simple.
```

---

# 29. Future / Deferred Screens — Design-Ready Only

These screens can be designed now, but should be visually marked as future-ready if implementation is delayed.

## 29.1 Dhikr Reminders

### Design

- Dhikr list.
- Reminder time.
- Count/streak.
- Gentle spiritual cards.

### Prompt

```text
Design a future Dhikr Reminders screen with dhikr cards, reminder times, completion check, and soft spiritual visuals. Make it consistent with the Prayer module.
```

## 29.2 Fasting Tracker

### Design

- Fasting calendar.
- Today fast status.
- Suhoor/Iftar times.
- Ramadan and optional voluntary fasting.

### Prompt

```text
Design a Fasting Tracker screen with calendar, today fasting status, Suhoor/Iftar cards, and fast logging. Use modern Ramadan-friendly styling.
```

## 29.3 Islamic Calendar

### Design

- Hijri date.
- Events.
- Ramadan/Eid highlights.
- Monthly calendar.

### Prompt

```text
Design an Islamic Calendar screen with Hijri date, event cards, monthly calendar, Ramadan/Eid highlights, and clean spiritual styling.
```

## 29.4 Goal Roadmap Generator

### Design

- Goal input.
- AI-generated milestones.
- Tasks/habits preview.
- Confirm before saving.

### Prompt

```text
Design a Goal Roadmap Generator screen where the user enters a long-term goal and AI suggests milestones, tasks, habits, and reminders. Include preview and confirm controls.
```

## 29.5 Study Planner AI

### Design

- Study goal.
- Exam date.
- Available time.
- Generated plan preview.

### Prompt

```text
Design a Study Planner AI screen for students. Include exam/goal input, available time, subject list, generated study plan preview, and confirm/edit actions.
```

## 29.6 Weekly Life Review

### Design

- Wins.
- Struggles.
- Stats.
- Reflection.
- Next week suggestions.

### Prompt

```text
Design a Weekly Life Review screen with wins, struggles, completed tasks, focus minutes, habits, prayer logs, reflection field, and next-week suggestions.
```

## 29.7 Motivation Engine

### Design

- Supportive message card.
- Streak recovery.
- Encouragement.
- No guilt/shame wording.

### Prompt

```text
Design a Motivation screen/card with supportive non-guilt wording, streak recovery, encouragement, and simple next step. Keep it emotionally safe.
```

---

# 30. Global UX Rules

## 30.1 Primary action rule

Every screen must have one obvious primary action.

Examples:

- Home: Quick Capture / View your day
- Tasks: Add task
- Focus: Start focus
- Prayer: Mark prayer / View times
- Notes: Add note
- Journal: New entry
- AI: Ask AI
- Settings: Save

## 30.2 Never hide important flows

AI and Voice must be reachable from:

- Home
- Quick Capture
- Tasks
- Notes
- AI Assistant

Prayer must be visible from:

- Home dashboard
- Prayer tab

## 30.3 Confirmation rule

Require confirmation for:

- delete
- logout
- AI applying schedule/tasks
- voice destructive actions
- changing prayer settings
- deleting account

## 30.4 Beginner-friendly rule

Use friendly labels, not technical wording.

Bad:

- “execute automation”
- “persist object”
- “parse entity”

Good:

- “Create task”
- “Save plan”
- “AI found these details”

## 30.5 Spiritual respect rule

Spiritual features must be respectful:

- no playful jokes on prayer screens
- no loud neon visuals
- no guilt/shame language for missed prayers
- supportive tone only

## 30.6 Accessibility rules

- sufficient contrast
- tap targets at least 44 px
- text scalable
- icons always paired with labels when needed
- RTL support for Arabic
- not color-only status indicators

---

# 31. Prompt Pack for Google Stitch

## 31.1 Full app master prompt

```text
Design the complete Smart Life Planner mobile app UI/UX.

Use the uploaded App Preview image as the master visual reference. The Home screen must be a near-clone of that preview, and every other screen must follow the same visual language: premium light lavender/off-white background, rounded white cards, purple/pink gradients, gold highlights, soft shadows, calm spacing, modern typography, and subtle polished animations.

Smart Life Planner is an AI-powered personal life operating system that combines tasks, projects, notes, habits, focus sessions, journaling, reminders, prayer routines, Quran goals, AI planning, voice input, analytics, and adaptive scheduling.

Target users:
- students
- busy workers
- Muslims who want prayer + productivity
- people who want AI planning
- beginners who need simple task management
- people who want all-in-one productivity
- people who want AI in productivity management

Design style:
- premium
- clean
- calm
- modern productivity
- spiritually respectful
- AI-powered
- beginner-friendly
- not childish
- not cluttered
- not dark/cosmic

Navigation:
Use five top-level tabs:
Home, Tasks, Focus, Prayer, Profile.
Add a center floating plus button for Quick Capture.

Design all key screens:
Splash, Welcome, Sign In, Sign Up, Verify Email, Forgot Password, Onboarding, Home, Quick Capture, Tasks, Task Details, Create Task, Projects, Schedule, Notes, Note Editor, Habits, Habit Details, Focus, Active Focus Session, Prayer, Quran Goals, Qibla, Ramadan Mode, Journal, AI Assistant, Voice Capture, Analytics, Notifications, Profile, Settings, Privacy, Support, and system states.

Use best practices inspired by:
- TickTick for task clarity and fast capture
- Notion for structured modular pages
- Google Keep for notes grid and quick capture
- Focus To-Do for focus timer clarity

Do not copy competitor branding. Create an original Smart Life Planner interface.

Every screen must include:
- normal state
- loading state
- empty state
- error state
- success state
- no internet state
- clear primary action
- consistent card and button style
- smooth transitions
- Flutter-ready structure

The app should feel stunning, professional, cohesive, and ready for a real product launch.
```

## 31.2 Home screen near-clone prompt

```text
Create the Smart Life Planner Home screen as a near-clone of the uploaded App Preview. Match the layout exactly: header with logo/greeting/date/notification/avatar, large gradient progress summary card, two cards for Next Prayer and Focus Session, Today’s Tasks card, Habits Overview card, AI Suggestion card, and floating bottom navigation with center plus button.

Use the same light lavender background, white rounded cards, purple/pink gradients, gold highlight, soft shadows, smooth spacing, clean typography, and premium polished style.

Do not simplify. Do not redesign. Do not create a generic dashboard. Match the uploaded App Preview as closely as possible.
```

## 31.3 Full design system prompt

```text
Create a complete design system for Smart Life Planner based on the uploaded App Preview. Include colors, typography, spacing, radius, shadows, buttons, inputs, cards, task cards, note cards, dashboard cards, bottom sheets, dialogs, loading skeletons, empty states, error states, success states, offline banners, bottom navigation, icon style, and animation principles.

The system must support light mode, future dark mode, English and Arabic/RTL, productivity workflows, spiritual screens, AI assistant screens, and Flutter implementation.
```

## 31.4 Onboarding prompt

```text
Design the complete Smart Life Planner onboarding flow: onboarding start, language selection, city/country, prayer calculation method, main goals, wake-up time, sleep time, work/study hours, notification permission, microphone permission, location permission, onboarding summary, and personalization complete.

Use premium soft lavender backgrounds, rounded cards, progress indicator, bottom primary button, friendly illustrations, and the same style as the App Preview.
```

## 31.5 Tasks prompt

```text
Design the Smart Life Planner Tasks module with Tasks Main, Inbox, Today, Upcoming, Projects, Project Details, Create/Edit Task, Task Details, Subtasks, Reminder Setup, Recurrence Setup, and Schedule/Calendar View.

Use TickTick-inspired clarity but original Smart Life Planner branding. Include rounded task cards, filters, chips, progress, priorities, due dates, subtasks, and quick actions. Keep it clean and premium.
```

## 31.6 Notes prompt

```text
Design the Smart Life Planner Notes module inspired by Google Keep and Notion, but in the App Preview style. Include Notes grid, search, filters, note editor, checklist editor, voice note preview, photo note, tags manager, pinned notes, and archived notes. Use soft pastel note cards and premium spacing.
```

## 31.7 Focus prompt

```text
Design the Focus module for Smart Life Planner. Include Focus Home, Active Focus Session, Pause/Resume, Session Complete, Break Timer, Focus History, and Focus Settings. Use a large circular timer, calming visuals, smooth timer animation, and premium purple/pink gradients.
```

## 31.8 Prayer prompt

```text
Design the Prayer and Spiritual module for Smart Life Planner. Include Prayer Home, Prayer Times, Prayer Tracking, Prayer History, Quran Goals, Quran Progress, Qibla, Ramadan Mode, Athan Settings, Prayer Settings, and Missed Prayer Tracking. Use modern respectful spiritual visuals, soft mosque/book/crescent icons, and the same premium style as the App Preview.
```

## 31.9 AI + Voice prompt

```text
Design the AI and Voice experience for Smart Life Planner. Include AI Assistant Home, AI Chat, AI Task Parser Preview, AI Daily Plan Preview, Next Best Action, Voice Recording, and Voice Transcript Preview. AI must feel helpful and safe. All AI actions must show preview and confirmation before saving.
```

## 31.10 Profile/settings prompt

```text
Design the Profile and Settings area for Smart Life Planner. Include Profile Home, Account Settings, Edit Profile, Appearance, Language, Notification Settings, Privacy & Data, Sync Status, Help & Support, Feedback, About, Change Password, Sign Out Confirmation, and Delete Account Confirmation. Use clean grouped settings cards and premium calm styling.
```

---

# 32. Final Quality Checklist

Before accepting any Stitch result, check:

## 32.1 Visual consistency

- Home matches App Preview.
- Other screens use same card style.
- Colors feel consistent.
- Typography feels consistent.
- Buttons look from same system.
- Icons are same stroke/style.
- Shadows are soft.
- Radius is consistent.

## 32.2 UX quality

- every screen has clear primary action.
- empty states are helpful.
- error states are friendly.
- no screen is overcrowded.
- quick capture is always easy.
- prayer is visible and accessible.
- AI is accessible but not intrusive.
- beginner user can understand screens.

## 32.3 Product alignment

- supports tasks.
- supports notes.
- supports habits.
- supports focus.
- supports prayer.
- supports journal.
- supports AI.
- supports voice.
- supports analytics.
- supports reminders.
- supports settings.
- supports onboarding.

## 32.4 Flutter readiness

- screen layout can be built with Flutter widgets.
- cards are reusable.
- bottom nav is reusable.
- components are systematic.
- responsive spacing is clear.
- no impossible web-only design.

## 32.5 Do not accept if

- Home does not match the App Preview.
- Screen becomes too dark or cosmic.
- Cards are square/flat.
- Navigation is inconsistent.
- Prayer is hidden.
- AI is hidden.
- Quick capture is missing.
- Empty states are missing.
- Buttons are inconsistent.
- Text is unreadable.
- The app feels like multiple unrelated apps.

---

# 33. Final Instruction to Google Stitch

Design Smart Life Planner like a real premium product.

The app should look like:

- TickTick-level clarity
- Notion-level structure
- Google Keep-level capture simplicity
- Focus To-Do-level focus clarity
- plus unique Muslim prayer/spiritual integration
- plus AI-powered planning

But the final result must be original, cohesive, and visually aligned with the uploaded App Preview.

The Home screen is the visual anchor.  
Every other screen must look like it belongs to the same app.

Create a stunning mobile app design system and complete screen set that a Flutter developer can rebuild directly.
