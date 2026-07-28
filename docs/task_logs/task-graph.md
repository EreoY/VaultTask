## Phase 223: Re-architect DashboardPage for 100% Home Floating Nav Transparency & 160px Calendar Scroll Padding [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Home Page Structure & Transparency Alignment (`dashboard_page.dart`)**:
>    - Remove nested `Scaffold` and nested `SafeArea` from `DashboardPage` so it matches `BoardsPage` (`boards_page.dart`) structure by returning `SingleChildScrollView` directly with transparent background.
>    - Update `SingleChildScrollView` bottom padding in `dashboard_page.dart` to `const EdgeInsets.only(bottom: 160)` so `FloatingBottomNavBar` floats 100% transparently over `AetherDynamicBackdrop` without white strip artifacts.
> 2. **Calendar Daily Timeline & Monthly Grid 160px Scroll Clearance (`daily_timeline_view.dart` & `calendar_page.dart`)**:
>    - In `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`, increase `ListView.builder` bottom padding to `160` (e.g. `bottom: isMobile ? 160 : 110`) so the 24:00 timeline slot scrolls 100% clear above `FloatingBottomNavBar`.
>    - In `my_ai_assistant/lib/ui/calendar/calendar_page.dart`, update `_buildMonthlyGrid()` bottom padding to `160` (e.g. `EdgeInsets.fromLTRB(isMobile ? 16 : 48, 0, isMobile ? 16 : 48, 160)`).
> 3. **Static Analysis Verification**:
>    - Run `flutter analyze` to ensure 0 compilation errors or static warnings.

- [x] Task 223.1: Re-architect `dashboard_page.dart` by removing nested `Scaffold` & `SafeArea` and returning `SingleChildScrollView` directly with 160px bottom padding, making Home page background 100% transparent matching `boards_page.dart`.
- [x] Task 223.2: Update `daily_timeline_view.dart` `ListView.builder` bottom padding to `isMobile ? 160 : 110` so 24:00 timeline slot scrolls 100% clear above `FloatingBottomNavBar`.
- [x] Task 223.3: Update `calendar_page.dart` `_buildMonthlyGrid()` bottom padding to `isMobile ? 160 : 110`.
- [x] Task 223.4: Perform static analysis (`flutter analyze`).

### Task 223.1: Remove nested Scaffold & SafeArea in dashboard_page.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** Replace `Scaffold` and `SafeArea` wrapper with a direct `SingleChildScrollView` (or `Column` layout matching `boards_page.dart`) with `padding: const EdgeInsets.only(bottom: 160)`.
- **Why:** Resolve user report that Home page still has a white non-transparent strip behind floating bottom navbar. Nested Scaffold & SafeArea interfere with outer Scaffold's `extendBody: true` in `AppShell`.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Home page renders with 100% floating navbar transparency over dynamic backdrop.

### Task 223.2: Increase bottom scroll padding in daily_timeline_view.dart to 160px
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`
- **Action:** Update `ListView.builder` bottom padding from `110` to `isMobile ? 160 : 110`.
- **Why:** Resolve user report that 24:00 timeline slot on mobile calendar is obscured by floating bottom navbar.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** 24:00 timeline slot scrolls completely clear above floating bottom navbar on mobile.

### Task 223.3: Increase bottom scroll padding in calendar_page.dart to 160px
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** Update `_buildMonthlyGrid()` bottom padding from `110` to `isMobile ? 160 : 110`.
- **Why:** Ensure monthly calendar grid also has 160px clearance matching daily timeline.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Monthly calendar grid scrolls cleanly above floating bottom navbar.

### Task 223.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`, `my_ai_assistant/lib/ui/calendar/widgets/daily_timeline_view.dart`, `my_ai_assistant/lib/ui/calendar/calendar_page.dart`
- **Action:** Execute `flutter analyze` and confirm zero errors.
- **Why:** Maintain codebase quality and strict adherence to project standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** Flutter analyze passes with 0 issues.
