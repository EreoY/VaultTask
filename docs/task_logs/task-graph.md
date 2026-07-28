## Phase 239: Android 3-Button System Navigation Bar Translucency & Canvas Background Fix [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Android System Navigation Bar Contrast Enforcement (`main.dart`)**:
>    - In `my_ai_assistant/lib/main.dart`:
>    - Ensure `SystemChrome.setSystemUIOverlayStyle` configures `systemNavigationBarContrastEnforced: false`, `systemNavigationBarColor: Colors.transparent`, `systemNavigationBarDividerColor: Colors.transparent`, and `systemNavigationBarIconBrightness: Brightness.dark` so Android 10+ does NOT forcibly paint an opaque grey/translucent scrim behind the 3 bottom system navigation buttons.
> 2. **Web Canvas & Glass Pane Background CSS (`web/index.html`)**:
>    - In `my_ai_assistant/web/index.html`:
>    - Add CSS `<style>body, html, flt-glass-pane { background-color: #F8F9FA !important; }</style>` inside `<head>` to ensure the root canvas background behind transparent system bars matches the app theme `#F8F9FA`.
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 239.1: Ensure `systemNavigationBarContrastEnforced: false` and `systemNavigationBarColor: Colors.transparent` in `main.dart`.
- [x] Task 239.2: Add CSS `body, html, flt-glass-pane { background-color: #F8F9FA !important; }` in `web/index.html`.
- [x] Task 239.3: Perform static analysis (`flutter analyze`).

### Task 239.1: Ensure systemNavigationBarContrastEnforced: false in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Verify and maintain `systemNavigationBarContrastEnforced: false` alongside `systemNavigationBarColor: Colors.transparent` in `main.dart` `SystemUiOverlayStyle` configuration.
- **Why:** Prevent Android 10+ from applying an automatic contrast scrim behind the bottom 3-button system navigation bar.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** `SystemUiOverlayStyle` explicitly disables system navigation bar contrast enforcement.

### Task 239.2: Add CSS background styling in web/index.html
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/index.html`
- **Action:** Insert `<style>body, html, flt-glass-pane { background-color: #F8F9FA !important; }</style>` inside `<head>` section of `index.html`.
- **Why:** Ensure background color under transparent bars matches theme background (`#F8F9FA`).
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** `index.html` contains the required CSS block for root canvas background styling.

### Task 239.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/web/index.html`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure code quality and stability.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes cleanly.

## Phase 238: Mobile Workspace Description Display Fix [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Default Workspace Description in State (`state_boards.dart`)**:
>    - In `my_ai_assistant/lib/state_managers/state_boards.dart`:
>    - Add non-empty default descriptions when initializing `personalDefault` (`id: 'default_personal'`) and `teamDefault` (`id: 'default_team_$uid'`).
>    - Default description text: `'พื้นที่สำหรับจัดเก็บงาน เอกสาร และสรุปการประชุมของทีม'`.
>    - Ensure `addWorkspace()` assigns a non-empty fallback description when no description is provided.
> 2. **Workspace Header Description Rendering (`boards_workspace_header.dart`)**:
>    - In `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`:
>    - Compute fallback description string `(selectedWorkspace?.description != null && selectedWorkspace!.description!.trim().isNotEmpty) ? selectedWorkspace!.description! : 'พื้นที่สำหรับจัดเก็บงาน เอกสาร และสรุปการประชุมของทีม'`.
>    - Render description text clearly on BOTH mobile and desktop screens without any `if (!isMobile)` restriction or hiding logic.
>    - Ensure text is styled with `GlassText.bodyMD()` (`fontSize: 12`, `color: GlassColors.onSurfaceVariant`), `maxLines: 2`, and `overflow: TextOverflow.ellipsis`.
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure 0 compilation errors or static warnings.

- [x] Task 238.1: Update `state_boards.dart` to assign default non-empty descriptions to default and newly created workspaces.
- [x] Task 238.2: Update `boards_workspace_header.dart` to render fallback description when description is empty/null, ensuring clean display on mobile and desktop screens.
- [x] Task 238.3: Perform static analysis (`flutter analyze`).

### Task 238.1: Update state_boards.dart to assign default non-empty descriptions to default and newly created workspaces
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/state_managers/state_boards.dart`
- **Action:** Update `personalDefault`, `teamDefault`, and `addWorkspace` in `state_boards.dart` to assign non-empty default description `'พื้นที่สำหรับจัดเก็บงาน เอกสาร และสรุปการประชุมของทีม'`.
- **Why:** Guarantee every workspace in state has a non-null, non-empty description.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Default workspaces and newly created workspaces possess non-empty descriptions.

### Task 238.2: Update boards_workspace_header.dart to render fallback description on mobile and desktop
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Compute fallback description string `'พื้นที่สำหรับจัดเก็บงาน เอกสาร และสรุปการประชุมของทีม'` when `selectedWorkspace?.description` is null or empty, and render description text cleanly on both mobile and desktop views.
- **Why:** Resolve issue where workspace description does not display on mobile devices.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Description text is always displayed under workspace title on both mobile and desktop screens.

### Task 238.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/state_managers/state_boards.dart`, `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 237: Smooth Slide Down Chat Input Bar [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Smooth Slide Down Chat Input Bar (`chat_page.dart`)**:
>    - In `my_ai_assistant/lib/ui/chat/chat_page.dart`, wrap `AetherChatInput` in smooth `AnimatedPadding` (duration 250ms, curve `easeInOut`) so chat input slides down to screen edge when nav bar hides.
> 2. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 237.1: Add smooth `AnimatedPadding` (duration 250ms, curve `easeInOut`) to `AetherChatInput` in `aether_chat_view.dart` / `chat_page.dart` so chat input slides down to screen edge when nav bar hides.
- [x] Task 237.2: Perform static analysis (`flutter analyze`).

### Task 237.1: Add smooth AnimatedPadding to AetherChatInput in chat_page.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/chat/chat_page.dart`
- **Action:** Add smooth `AnimatedPadding` (duration 250ms, curve `easeInOut`) to `AetherChatInput` in `chat_page.dart` so chat input slides down to screen edge when nav bar hides.
- **Why:** Ensure smooth animation of chat input bar when bottom navigation bar toggles visibility.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Chat input slides down smoothly when bottom navigation bar hides.

### Task 237.2: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/chat/chat_page.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 errors.

## Phase 236: Transparent 3-Button Bottom System Navigation Bar [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Viewport Fit Meta Tag (`web/index.html`)**:
>    - Add `viewport-fit=cover` to `web/index.html` viewport meta tag.
> 2. **Bottom Inset Removal (`floating_bottom_nav_bar.dart`)**:
>    - Set `SafeArea(bottom: false)` in `floating_bottom_nav_bar.dart` to remove bottom container inset strip.
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 236.1: Add `viewport-fit=cover` to `web/index.html` viewport meta tag.
- [x] Task 236.2: Set `SafeArea(bottom: false)` in `floating_bottom_nav_bar.dart` to remove bottom container inset strip.
- [x] Task 236.3: Perform static analysis (`flutter analyze`).

### Task 236.1: Add viewport-fit=cover to web/index.html viewport meta tag
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/index.html`
- **Action:** Add `viewport-fit=cover` to viewport meta tag.
- **Why:** Allow web viewport content to extend edge-to-edge covering notch and navigation bar insets.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Viewport meta tag contains `viewport-fit=cover`.

### Task 236.2: Set SafeArea(bottom: false) in floating_bottom_nav_bar.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/common/floating_bottom_nav_bar.dart`
- **Action:** Set `SafeArea(bottom: false)` in `floating_bottom_nav_bar.dart` to remove bottom container inset strip.
- **Why:** Eliminate unwanted extra padding below floating bottom navigation bar.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** `FloatingBottomNavBar` uses `SafeArea(bottom: false)`.

### Task 236.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/index.html`, `my_ai_assistant/lib/ui/common/floating_bottom_nav_bar.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 errors.

## Phase 235: Workspace Header Title & Description 2-Line Alignment [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Workspace Model Description Support (`workspace_model.dart`)**:
>    - In `my_ai_assistant/lib/models/workspace_model.dart`, add optional `description` field to `WorkspaceModel`.
>    - Update constructor, `fromMap`, `toMap`, `fromJson`, `toJson`, and `copyWith` to handle optional `description`.
> 2. **Workspace Header UI Update (`boards_workspace_header.dart`)**:
>    - In `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`:
>    - Update `boards_workspace_header.dart` to align Workspace Description with Title column and set `maxLines: 2` with `overflow: TextOverflow.ellipsis` (`..`).
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 235.1: Add optional `description` field to `WorkspaceModel` in `workspace_model.dart`.
- [x] Task 235.2: Update `boards_workspace_header.dart` to align Workspace Description with Title column and set `maxLines: 2` with `overflow: TextOverflow.ellipsis` (`..`).
- [x] Task 235.3: Perform static analysis (`flutter analyze`).

### Task 235.1: Add optional description field to WorkspaceModel in workspace_model.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/models/workspace_model.dart`
- **Action:** Add `final String? description;` to `WorkspaceModel` and update serialization methods (`fromMap`, `toMap`, `fromJson`, `toJson`, `copyWith`).
- **Why:** Allow workspace entities to store and provide description text to UI widgets.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** `WorkspaceModel` instantiates and serializes `description` field cleanly.

### Task 235.2: Update boards_workspace_header.dart to align Workspace Description with Title column and set maxLines: 2 with ellipsis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Align Workspace Description with Title column and set `maxLines: 2` with `overflow: TextOverflow.ellipsis`.
- **Why:** Truncate workspace description and align with title column per layout specifications.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Workspace Description aligns with Title column and truncates to 2 lines with ellipsis.

### Task 235.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/models/workspace_model.dart`, `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure code quality and adherence to guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports 0 errors.

## Phase 234: Compact Single-Line Chat Header & Minimalist Input Bar ("ข้อความ...") [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Chat Header Single-Line & Compact Restructuring (`chat_page.dart`)**:
>    - In `my_ai_assistant/lib/ui/chat/chat_page.dart`, update `_buildHeader()` for mobile and desktop views.
>    - Replace prominent "Global Chat" header (fontSize 24/48) and multi-line subtitle with a single-line, compact top bar.
>    - Set header title text to concise `'ข้อความ...'` formatted with `maxLines: 1`, `overflow: TextOverflow.ellipsis`, small font size (`fontSize: 12`), and `color: GlassColors.onSurfaceVariant`.
>    - Reduce container padding to maximize chat message reading viewport.
> 2. **Input Bar Hint Text & Space Optimization (`chat_input.dart`)**:
>    - In `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`, update text field `hintText` to concise `'ข้อความ...'` with `fontSize: 12`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and `color: GlassColors.onSurfaceVariant.withOpacity(0.5)`.
>    - Reduce `AetherChatInput` container padding to minimize vertical screen real estate consumption.
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation errors or static lint warnings.

- [x] Task 234.1: Compact `chat_page.dart` header to single-line `'ข้อความ...'` (`fontSize: 12`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`).
- [x] Task 234.2: Update `chat_input.dart` `hintText` to concise `'ข้อความ...'` and reduce container padding.
- [x] Task 234.3: Perform static analysis (`flutter analyze`).

### Task 234.1: Compact chat_page.dart header to single-line 'ข้อความ...'
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/chat/chat_page.dart`
- **Action:** Restructure `_buildHeader()` in `chat_page.dart` to render a single-line header with concise text `'ข้อความ...'`, `fontSize: 12`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and `color: GlassColors.onSurfaceVariant`.
- **Why:** Reduce header height footprint to maximize chat reading viewport.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Chat header renders as a single compact line with small font size.

### Task 234.2: Update chat_input.dart hintText to 'ข้อความ...' and reduce container padding
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** Update text field `hintText` to `'ข้อความ...'`, `fontSize: 12`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`, and reduce container padding.
- **Why:** Provide concise hint text and compact input bar layout.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Input bar displays concise hint text and compact padding.

### Task 234.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/chat/chat_page.dart`, `my_ai_assistant/lib/ui/chat/widgets/chat_input.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 errors.

## Phase 233: Workspace Mock Description Removal [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Workspace Header Description Clean-up (`boards_workspace_header.dart`)**:
>    - In `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`, remove mock description paragraph text under Workspace Title.
> 2. **Static Analysis Verification**:
>    - Execute `flutter analyze` to verify zero compilation errors or static warnings.

- [x] Task 233.1: Remove mock description paragraph text under Workspace Title in `boards_workspace_header.dart`.
- [x] Task 233.2: Perform static analysis (`flutter analyze`).

### Task 233.1: Remove mock description paragraph text under Workspace Title in boards_workspace_header.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Remove mock description paragraph text beneath Workspace Title.
- **Why:** Remove unnecessary clutter from workspace header.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Workspace header displays clean title without mock description.

### Task 233.2: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_workspace_header.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 errors.

## Phase 232: Transparent Edge-to-Edge System UI & Scroll-Aware Auto-Hiding Floating Navigation Bar [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Android Edge-to-Edge System Navigation Bar (`main.dart`)**:
>    - In `my_ai_assistant/lib/main.dart`, enable edge-to-edge UI mode via `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`.
>    - Update `SystemUiOverlayStyle` in `main()` and in `AppShell`'s `AnnotatedRegion` with `systemNavigationBarColor: Colors.transparent`, `systemNavigationBarDividerColor: Colors.transparent`, `systemNavigationBarIconBrightness: Brightness.dark`, and `systemNavigationBarContrastEnforced: false` to ensure Android system 3-button or gesture bar is 100% transparent.
> 2. **Scroll-Aware Auto-Hiding Floating Navigation Bar (`main.dart` & `floating_bottom_nav_bar.dart`)**:
>    - In `AppShell` (`_AppShellState` in `main.dart`), introduce `bool _isNavBarVisible = true;`.
>    - Wrap main body stack in `NotificationListener<UserScrollNotification>` (importing `package:flutter/rendering.dart`).
>    - Listen to scroll notifications: set `_isNavBarVisible = false` when `notification.direction == ScrollDirection.reverse` (user scrolling down to read), set `_isNavBarVisible = true` when `notification.direction == ScrollDirection.forward` (user scrolling up).
>    - Reset `_isNavBarVisible = true` in `_selectTab` so the nav bar is always visible when changing tabs.
>    - Wrap `FloatingBottomNavBar` in `AnimatedSlide(offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2.5), duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)` for smooth slide-down hiding and slide-up revealing.
> 3. **Static Analysis Verification**:
>    - Run `flutter analyze` to ensure 0 compilation errors or static warnings.

- [x] Task 232.1: Enable `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` and set `systemNavigationBarColor: Colors.transparent` in `main.dart`.
- [x] Task 232.2: Add `UserScrollNotification` direction listener and `_isNavBarVisible` state in `AppShell` (`main.dart`).
- [x] Task 232.3: Wrap `FloatingBottomNavBar` in `AnimatedSlide` with 250ms smooth curves animation in `main.dart`.
- [x] Task 232.4: Perform static analysis (`flutter analyze`).

### Task 232.1: Enable SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge) and transparent system navigation bar colors in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Add `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` in `main()` and update `SystemUiOverlayStyle` in `main()` and `AppShell`'s `AnnotatedRegion` with `systemNavigationBarColor: Colors.transparent`, `systemNavigationBarDividerColor: Colors.transparent`, `systemNavigationBarIconBrightness: Brightness.dark`, and `systemNavigationBarContrastEnforced: false`.
- **Why:** Allow mobile viewport content to draw under the Android system navigation bar with 100% transparency.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** System navigation bar renders transparently over app background.

### Task 232.2: Add _isNavBarVisible state and UserScrollNotification listener in AppShell
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Add `_isNavBarVisible` state boolean to `_AppShellState`, wrap main `Stack` in `NotificationListener<UserScrollNotification>`, update state based on `ScrollDirection.reverse` and `ScrollDirection.forward`, and reset to `true` in `_selectTab`.
- **Why:** Detect user scroll behavior across all main tabs to trigger hiding when scrolling down and showing when scrolling up.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Scroll notifications update `_isNavBarVisible` state correctly.

### Task 232.3: Wrap FloatingBottomNavBar in AnimatedSlide in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Wrap `FloatingBottomNavBar` in `AnimatedSlide(offset: _isNavBarVisible ? Offset.zero : const Offset(0, 2.5), duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)`.
- **Why:** Smoothly slide bottom floating navbar out of view when reading content down the screen and slide back up when scrolling up.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Navbar slides out of view on scroll down and slides back in on scroll up.

### Task 232.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/common/floating_bottom_nav_bar.dart`
- **Action:** Run `flutter analyze` and confirm 0 errors.
- **Why:** Ensure codebase health and quality.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.


## Phase 231: Seamless Mobile Top Status Bar & PWA Theme Color Alignment (#F8F9FA) [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **PWA Manifest Color Alignment (`web/manifest.json`)**:
>    - In `my_ai_assistant/web/manifest.json`, replace `"background_color": "#0175C2"` and `"theme_color": "#0175C2"` with `"background_color": "#F8F9FA"` and `"theme_color": "#F8F9FA"`.
> 2. **HTML Meta Tags Theme Color Alignment (`web/index.html`)**:
>    - In `my_ai_assistant/web/index.html`, insert `<meta name="theme-color" content="#F8F9FA">` in `<head>`.
>    - Update `<meta name="apple-mobile-web-app-status-bar-style" content="black">` to `<meta name="apple-mobile-web-app-status-bar-style" content="default">` so iOS/Safari status bar renders seamlessly with `#F8F9FA`.
> 3. **System UI Overlay Style Verification (`main.dart`)**:
>    - Ensure `SystemUiOverlayStyle` in `main.dart` maintains `statusBarColor: Colors.transparent` (or `GlassColors.background`), `statusBarIconBrightness: Brightness.dark`, and `statusBarBrightness: Brightness.light` so system icons remain crisp and dark over `#F8F9FA`.
> 4. **Static Analysis Verification**:
>    - Execute `flutter analyze` to verify zero compilation errors or lint warnings.

- [x] Task 231.1: Update `web/manifest.json` `background_color` and `theme_color` to `#F8F9FA`.
- [x] Task 231.2: Update `web/index.html` with `<meta name="theme-color" content="#F8F9FA">` and `apple-mobile-web-app-status-bar-style` to `default`.
- [x] Task 231.3: Verify `SystemUiOverlayStyle` in `lib/main.dart` for transparent status bar with dark icons.
- [x] Task 231.4: Perform static analysis (`flutter analyze`).

### Task 231.1: Update web/manifest.json theme_color and background_color to #F8F9FA
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/manifest.json`
- **Action:** Replace `"background_color": "#0175C2"` and `"theme_color": "#0175C2"` with `#F8F9FA`.
- **Why:** Eliminate default Flutter blue PWA theme color `#0175C2` causing mobile browser status bar tinting.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** PWA manifest specifies `#F8F9FA` theme and background colors matching app design system.

### Task 231.2: Add HTML meta theme-color tag and status bar style in web/index.html
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/index.html`
- **Action:** Add `<meta name="theme-color" content="#F8F9FA">` and update `apple-mobile-web-app-status-bar-style` to `default`.
- **Why:** Control mobile browser top status bar / notch background color to blend 100% seamlessly with `#F8F9FA`.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** HTML head section contains valid `#F8F9FA` theme-color meta tag.

### Task 231.3: Verify Flutter SystemUiOverlayStyle in lib/main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Confirm `SystemUiOverlayStyle` sets `statusBarColor: Colors.transparent`, `statusBarIconBrightness: Brightness.dark`, `statusBarBrightness: Brightness.light`.
- **Why:** Guarantee native/web Flutter status overlay remains transparent with dark readable icons on light background.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Status bar icons render dark on transparent background.

### Task 231.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/web/manifest.json`, `my_ai_assistant/web/index.html`, `my_ai_assistant/lib/main.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Guarantee codebase health and zero build errors.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** Static analysis completes with 0 errors.

## Phase 230: Mobile Status Bar Theme & Navigation Index Sync Fix [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **System UI Overlay Enforcer (`main.dart` & `AppShell`)**:
>    - In `my_ai_assistant/lib/main.dart`, wrap `AppShell` with `AnnotatedRegion<SystemUiOverlayStyle>` specifying `statusBarColor: Colors.transparent`, `statusBarIconBrightness: Brightness.dark`, `statusBarBrightness: Brightness.light`, `systemNavigationBarColor: Colors.transparent`, and `systemNavigationBarIconBrightness: Brightness.dark`.
>    - Ensure status bar background remains transparent without default Flutter/Android blue (`#007BC1` / `#2196F3`) header overlay.
> 2. **Navigation Tab Index Alignment (`main.dart`, `dashboard_page.dart`, `floating_bottom_nav_bar.dart`)**:
>    - Align `AppShell._buildScreen(index)` so tab indices match `FloatingBottomNavBar` (0: Dashboard, 1: Boards, 2: Calendar, 3: Profile, 4: Chat).
>    - Update `FloatingBottomNavBar` item indices or `AppShell` tab indices so the 4th navbar item ('Profile' icon) navigates directly to `ProfilePage`.
>    - Update `DashboardPage` header profile avatar `onProfilePressed` callback to navigate to `ProfilePage`.
> 3. **Bottom Padding & SafeArea Adjustment (`dashboard_page.dart`)**:
>    - Ensure `DashboardPage` scroll view bottom padding (`bottom: 120 + MediaQuery.of(context).padding.bottom`) prevents cards under "Your plan" and "Recent Tasks" from being obscured by `FloatingBottomNavBar`.
> 4. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or lint errors.

- [x] Task 230.1: Wrap `AppShell` in `AnnotatedRegion<SystemUiOverlayStyle>` in `main.dart` to enforce transparent status bar and dark icons.
- [x] Task 230.2: Align navigation tab indices in `main.dart`, `dashboard_page.dart`, and `floating_bottom_nav_bar.dart` so Profile avatar/icon navigates to `ProfilePage`.
- [x] Task 230.3: Adjust `DashboardPage` bottom scroll padding with `MediaQuery` safe area to prevent `FloatingBottomNavBar` overlap.
- [x] Task 230.4: Perform static analysis (`flutter analyze`).

### Task 230.1: Enforce System UI Overlay Style with AnnotatedRegion in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Wrap `AppShell` widget tree in `AnnotatedRegion<SystemUiOverlayStyle>` with `statusBarColor: Colors.transparent`, `statusBarIconBrightness: Brightness.dark`, `statusBarBrightness: Brightness.light`, and `systemNavigationBarColor: Colors.transparent`.
- **Why:** Prevent Android system theme or Flutter Scaffold from resetting status bar to default bright blue (`#007BC1` / `#2196F3`).
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Status bar background remains transparent with dark icons over light app background on Android.

### Task 230.2: Align navigation tab indices for Profile and Chat
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`, `my_ai_assistant/lib/ui/common/floating_bottom_nav_bar.dart`
- **Action:** Fix tab index routing so tapping Profile avatar in header or Profile icon (4th tab) in `FloatingBottomNavBar` opens `ProfilePage` instead of `ChatPage`.
- **Why:** Fix profile navigation mismatch where Profile icon opens AI Chat screen.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Tapping Profile avatar or Profile nav icon correctly displays `ProfilePage`.

### Task 230.3: Adjust DashboardPage scroll view padding
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** Update `SingleChildScrollView` padding to account for `FloatingBottomNavBar` height plus system bottom safe area padding.
- **Why:** Ensure bottom cards ("Your plan" audio/AI cards and "Recent Tasks") are not obscured by floating nav bar.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** All dashboard content scrolls cleanly above floating nav bar.

### Task 230.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`, `my_ai_assistant/lib/ui/dashboard/dashboard_page.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 229: Mobile System Status Bar Theme Color Fix [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Configure SystemChrome System UI Overlay Style (`main.dart`)**:
>    - In `my_ai_assistant/lib/main.dart`, configure `SystemChrome.setSystemUIOverlayStyle` with transparent status bar (`statusBarColor: Colors.transparent`) and matching icon brightness (`statusBarIconBrightness: Brightness.dark` / `statusBarBrightness: Brightness.light`).
> 2. **Update MaterialApp Theme Definition Seed Color (`main.dart`)**:
>    - Update `MaterialApp` theme definition in `main.dart` with seed color `GlassColors.primary` (`#1E1E24`) to eliminate default Flutter blue (`#2196F3`).
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or lint errors across the application.

- [x] Task 229.1: Configure `SystemChrome.setSystemUIOverlayStyle` in `main.dart` with transparent status bar and matching icon brightness.
- [x] Task 229.2: Update `MaterialApp` theme definition with seed color `GlassColors.primary` in `main.dart` to eliminate default Flutter blue (`#2196F3`).
- [x] Task 229.3: Perform static analysis (`flutter analyze`).

### Task 229.1: Configure SystemChrome.setSystemUIOverlayStyle in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Configure `SystemChrome.setSystemUIOverlayStyle` in `main.dart` with `statusBarColor: Colors.transparent` and matching icon brightness.
- **Why:** Fix mobile status bar background color artifacts on startup and runtime.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Status bar background is transparent with correct icon contrast.

### Task 229.2: Update MaterialApp theme definition seed color in main.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Set `ColorScheme.fromSeed(seedColor: GlassColors.primary)` in `MaterialApp` theme in `main.dart`.
- **Why:** Replace default Flutter blue seed color (`#2196F3`) with `GlassColors.primary` (`#1E1E24`).
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Default blue theme tint replaced with monochrome design system primary color.

### Task 229.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 228: Desktop Sidebar Nested Kanban Sub-Expansion Removal [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Sidebar Workspace Nested Board Sub-Expansion Removal (`aether_side_nav.dart`)**:
>    - In `my_ai_assistant/lib/ui/common/aether_side_nav.dart`, locate the expanded workspace mapping loop (`workspaces.map((workspace) { ... })`).
>    - Remove the conditional nested board sub-expansion list (`if (isSelected) ...[ ...boards.where((b) => b.workspaceId == workspace.id).map((board) { ... }) ]`).
>    - Ensure clicking a workspace row triggers `stateBoards.setSelectedWorkspace(workspace)`, `stateBoards.setSelectedBoard(null)`, and `widget.onItemSelected(1)` to cleanly open the Workspace Overview (`BoardsPage`) displaying module Bento cards (Board, Docs, Meetings).
> 2. **Unused State Clean-Up**:
>    - Clean up unused board selections (`boards`, `selectedBoardId`) from `_AetherSideNavState.build()` if no longer needed by sidebar rendering.
> 3. **Static Analysis Verification**:
>    - Execute `flutter analyze` to ensure zero compilation or lint errors across the application.

- [x] Task 228.1: Remove nested sub-expansion list of Kanban boards in `aether_side_nav.dart`.
- [x] Task 228.2: Clean up unused board selection state getters in `aether_side_nav.dart`.
- [x] Task 228.3: Perform static analysis (`flutter analyze`).

### Task 228.1: Remove nested Kanban boards sub-expansion list under workspaces in aether_side_nav.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:** Remove lines 361-436 in `aether_side_nav.dart` containing `if (isSelected) ...[ const SizedBox(height: 4), ...boards.where((b) => b.workspaceId == workspace.id).map((board) { ... }) ]`.
- **Why:** Resolve user request ("ตอนที่เรากดไปที่เวิร์คสเปรชไหนแล้วมันจะทำการโชว์ว่ามีกี่บอร์ดถูกไหมเอาออกเลยเพราะตอนนี้พอกดไปที่บอกนั่นแล้วมันจะไปคันบันเลยคือตอนนี้เรามีหลายระบบมากไม่ได้เน้นแค่คันบันเฉยๆเเล้ว") by keeping sidebar navigation focused on workspace level selection.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Workspace entries render cleanly as top-level sidebar items without nested sub-boards, navigating directly to Workspace Overview (`BoardsPage`) on click.

### Task 228.2: Clean up unused board selection state getters in aether_side_nav.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:** Remove `boards` and `selectedBoardId` declarations from `_AetherSideNavState.build()` if no longer referenced.
- **Why:** Maintain clean, efficient state selectors without unnecessary context rebuilds.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Code compiles without unused variable warnings.

### Task 228.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/common/aether_side_nav.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 227: Grouped Action Items with Sequential Numbered Categories [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **AI Prompt System Instruction Rules (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` (meeting and document modes) and `_handleRefine` to support **Grouped Action Items**:
>      - **Rule 4 Update**: Allow `## Action Items` section to be organized into numbered category headers (`1. กลุ่มหัวข้อแรก`, `2. กลุ่มหัวข้อถัดไป`, `3. ...`).
>      - Under each numbered category header, allow sub-checklist items (`- [ ] งานที่ 1`, `- [ ] งานที่ 2`).
>      - Sequential group numbers MUST count strictly in order (`1.`, `2.`, `3.`) without skips or resets within the Action Items section.
>      - **Rule 8 Update**: Sub-checklist items must start at the beginning of their own line (`- [ ] ข้อความ` or indented `  - [ ] ข้อความ`) under the numbered category header, and must not be combined on the same line as the category title.
> 2. **Markdown Block Editor Parser & Serializer Audit (`markdown_block_editor.dart`)**:
>    - **Check `parseMarkdownToBlocks()`**: Verify `todoUnchecked` and `todoChecked` regexes handle indented or non-indented checklist items (`- [ ]` / `- [x]`) under numbered category headers (`1. กลุ่มหัวข้อ`). Confirm `1. กลุ่ม...` parses as `type: 'numbered'` and sub-checklists parse as `type: 'todo'`.
>    - **Check `preserveCheckedItems()`**: Confirm matching logic normalizes text and preserves `isChecked: true` states across AI summary refinements even when items are grouped under numbered headers.
>    - **Fix `serializeBlocksToMarkdown()`**: Fix `serializeBlocksToMarkdown()` so `numberedIndex` does NOT reset when encountering `todo` or `bullet` blocks, and only resets upon major section breaks (`h1`, `h2`, `paragraph`).
>    - **Fix `_BlockRow` Numbered Prefix Indexing**: In `MarkdownBlockEditor.build()`, update the backwards lookup loop for `block.type == 'numbered'` so it skips over intervening `todo` and `bullet` blocks to calculate the correct sequential index (`1.`, `2.`, `3.`) relative to the current section.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 227.1: Update system prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) for Grouped Action Items with sequential numbered categories (`1.`, `2.`, `3.`) and sub-checklists (`- [ ]`).
- [x] Task 227.2: Audit and fix `markdown_block_editor.dart` (`serializeBlocksToMarkdown()` and `_BlockRow` index calculation) so intervening `todo`/`bullet` blocks do not reset numbered category indexes (`1.`, `2.`), ensuring correct rendering, serialization, and checked state preservation (`preserveCheckedItems`).
- [x] Task 227.3: Perform static analysis (`flutter analyze`).

### Task 227.1: Update system prompt instructions in ai_summarize_sheet.dart for Grouped Action Items
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update Rule 4 and Rule 8 in `_handleSummarize` (meeting and document prompts) and `_handleRefine` to permit numbered category headers (`1. กลุ่มหัวข้อแรก`, `2. กลุ่มหัวข้อถัดไป`) under `## Action Items` with sub-checklists (`- [ ]`), requiring sequential ordering (`1.`, `2.`, `3.`).
- **Why:** Provide flexibility for AI to organize action items into numbered category groups as requested by prompt directive.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly specifies grouped action items format with sequential numbers.

### Task 227.2: Audit and fix markdown_block_editor.dart for Grouped Action Items support
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Audit `parseMarkdownToBlocks()` and `preserveCheckedItems()`. Update `serializeBlocksToMarkdown()` and `_BlockRow` index calculation so intervening `todo` and `bullet` blocks do not reset `numberedIndex`, allowing sequential numbered headers (`1.`, `2.`, `3.`) to increment correctly when separated by todo items.
- **Why:** Prevent UI and serialized Markdown from resetting category numbers back to `1.` after every checklist item.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Numbered headers increment correctly (`1.`, `2.`, `3.`) in both editor rendering and serialized Markdown string, with checkbox states preserved.

### Task 227.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and ensure no lint warnings or syntax errors.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` returns zero errors.

## Phase 226: AI System Prompt Strict Checklist Scope & Prefix Placement Rules [x] Completed

> **Architecture Mandate:**
> 1. **AI Prompt Rules - Checklist Scope Rule (Rule A)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` (meeting and document modes) and `_handleRefine`:
>    - Add explicit Rule 7: Checklists (`- [ ]` / `- [x]`) are strictly allowed ONLY under the `## Action Items` section. All other sections (Summary, Topics, Key Points) MUST NOT contain checkboxes.
> 2. **AI Prompt Rules - Checklist Prefix Placement Rule (Rule B)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` and `_handleRefine`:
>    - Add explicit Rule 8: Checklists MUST ALWAYS sit at the VERY FRONT (beginning) of the line (`- [ ] <task_text>` or `- [x] <task_text>`). Checkboxes must NEVER be placed in the middle or at the end of a sentence, nor appended after numbered or bullet points.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 226.1: Update prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) to enforce Rule A (Checklists allowed ONLY under `## Action Items` section).
- [x] Task 226.2: Update prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) to enforce Rule B (Checklists MUST sit at VERY FRONT of the line `- [ ] <task_text>`, NEVER middle/end/numbered line).
- [x] Task 226.3: Perform static analysis (`flutter analyze`).

### Task 226.1: Update prompt instructions in ai_summarize_sheet.dart to enforce Rule A (Checklists ONLY under ## Action Items)
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Rule 7 to system instruction strings in `_handleSummarize` and `_handleRefine`: "7. กฎตำแหน่งของเช็กลิสต์: สัญลักษณ์เช็กลิสต์ (- [ ] หรือ - [x] ) อนุญาตให้มีได้เฉพาะในหัวข้อ Action Items (## Action Items) เท่านั้น หัวข้ออื่นทั้งหมด (เช่น สรุปประเด็น, รายละเอียดการประชุม, ประเด็นสำคัญ) ห้ามใส่เช็กลิสต์เด็ดขาด".
- **Why:** Prevent AI from putting checkboxes in non-action item sections (Summary, Topics, Key Points).
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly restricts checkboxes to the Action Items section.

### Task 226.2: Update prompt instructions in ai_summarize_sheet.dart to enforce Rule B (Checklists MUST sit at VERY FRONT of line)
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Rule 8 to system instruction strings in `_handleSummarize` and `_handleRefine`: "8. กฎการวางสัญลักษณ์เช็กลิสต์: สัญลักษณ์เช็กลิสต์ต้องอยู่ด้านหน้าสุดของบรรทัดเท่านั้น เช่น '- [ ] ข้อความ' ห้ามนำเช็กลิสต์ไปวางตรงกลางข้อความ ต่อท้ายข้อความ หรือต่อท้ายรายการลำดับตัวเลขเด็ดขาด".
- **Why:** Prevent AI from placing checkboxes at middle/end of sentences or numbered lines, ensuring Markdown parser can parse todo items reliably.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly instructs AI to place checkboxes exclusively at line beginnings.

### Task 226.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Execute `flutter analyze` and confirm zero errors.
- **Why:** Ensure codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 issues.

## Phase 225: Checklist Exemption from Numbered List Conversion (> 3 Items Rule) [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **AI Summarizer Prompt Rules Update (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update Rule 4 in prompt instructions for `_handleSummarize` (both meeting and document modes) and `_handleRefine`:
>      - Explicitly state that Action Items / checklist items (`- [ ]` / `- [x]`) are EXEMPT from the "more than 3 items -> numbered list" rule and MUST always remain as pure checkboxes (`- [ ]` / `- [x]`) regardless of item count.
> 2. **Markdown Block Parser Checklist Numbered Prefix Handling (`markdown_block_editor.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, update `parseMarkdownToBlocks()` regexes for `todoUnchecked` and `todoChecked`:
>      - Change regex pattern to match numbered prefixes before brackets (e.g., `^\s*(?:[-*]|\d+[.)])\s*\[\s\]\s*(.*)$` and `^\s*(?:[-*]|\d+[.)])\s*\[[xX]\]\s*(.*)$`).
>      - This guarantees any line formatted like `1. [ ] item` or `1) [x] item` is correctly parsed as `type: 'todo'` and serialized as `- [ ] item` or `- [x] item`.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 225.1: Update prompt instructions in `ai_summarize_sheet.dart` to explicitly exempt Action Items / checklist items (`- [ ]` / `- [x]`) from the > 3 items numbered list rule.
- [x] Task 225.2: Update `parseMarkdownToBlocks` regex in `markdown_block_editor.dart` to recognize numbered checkbox items (`1. [ ]`, `2. [x]`) as `type: 'todo'`.
- [x] Task 225.3: Perform static analysis (`flutter analyze`).

### Task 225.1: Update prompt instructions in ai_summarize_sheet.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update Rule 4 in system prompt strings in `_handleSummarize` (lines 292-293) and `_handleRefine` (line 369) to state: "4. กฎการใช้รายการย่อย: หากมีย่อย ให้ใช้รายการ "- " ได้สูงสุดแค่ 3 ข้อเท่านั้น หากมีย่อยมากกว่า 3 ข้อขึ้นไป ให้ใช้รายการลำดับตัวเลข ("1. ", "2. ", "3. "...) แทน (ข้อยกเว้น: รายการ Action Items หรือเช็กลิสต์ ให้ใช้ "- [ ] " หรือ "- [x] " เป็นเช็กลิสต์เสมอ ไม่ว่าจะมียี่สิบหรือกี่ข้อก็ตาม ห้ามเปลี่ยนเป็นรายการลำดับตัวเลขเด็ดขาด)".
- **Why:** Resolve bug where AI converts Action Items into numbered lists (`1. `, `2. `) when count > 3.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** AI prompt explicitly instructs LLM to keep Action Items as checkboxes regardless of count.

### Task 225.2: Update parseMarkdownToBlocks regex in markdown_block_editor.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Modify `todoUnchecked` and `todoChecked` regex in `parseMarkdownToBlocks` to allow optional digits/number prefixes (e.g. `^\s*(?:[-*]|\d+[.)])\s*\[\s\]\s*(.*)$` and `^\s*(?:[-*]|\d+[.)])\s*\[[xX]\]\s*(.*)$`).
- **Why:** Ensure any fallback or legacy numbered checkboxes (e.g. `1. [ ] Item`) are parsed as `type: 'todo'` rather than being misclassified by `numberedRe` as `type: 'numbered'`.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Numbered todo items parse as `todo` blocks and serialize back to pure `- [ ]` checkboxes.

### Task 225.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure code quality and adherence to guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 224: AI Summary Unchecked Checkbox Contrast & Session Stale State Synchronization [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Unchecked Checkbox High Contrast Styling (`markdown_block_editor.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, update the `- [ ]` unchecked checkbox container decoration styling:
>      - Change border color from `GlassColors.outlineVariant.withOpacity(0.4)` to a crisp, clear 1.5px border: `GlassColors.onSurfaceVariant.withOpacity(0.6)`.
>      - Change background fill from `Colors.transparent` to a subtle container fill: `GlassColors.onSurfaceVariant.withOpacity(0.05)`.
>      - This guarantees empty checkbox boxes `- [ ]` are 100% visible on both Light and Dark backgrounds.
> 2. **Stale Summary Loading & Real-Time Session Sync (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`:
>      - In `_loadCurrentSessionMessages()`: Load the newest AI summary message (`msgs.where((m) => !m.isUser).firstOrNull`). When `widget.initialSummary` is present and non-empty, apply `preserveCheckedItems(widget.initialSummary!, newestAiMsg.text)` so user-checked checkboxes from the meeting/doc are not overwritten by stale DB states.
>      - If the merged summary text differs from `newestAiMsg.text`, update `newestAiMsg` in RAM (`_chatMessages`) and sync to Cloudflare DB immediately via `ApiCloudflare.insertChatMessage`.
>      - When checkbox items are toggled in `MarkdownBlockEditor` inside `AiSummarizeSheet` (in `onChanged`), update `_summaryOutput` and `_chatMessages` in RAM and call `ApiCloudflare.insertChatMessage` immediately to persist to DB. If no AI message exists yet in the session, create a new AI message and insert into RAM and DB.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 224.1: Update `- [ ]` unchecked checkbox styling in `markdown_block_editor.dart` with 1.5px border (`GlassColors.onSurfaceVariant.withOpacity(0.6)`) and subtle fill (`GlassColors.onSurfaceVariant.withOpacity(0.05)`).
- [x] Task 224.2: Update `_loadCurrentSessionMessages()` in `ai_summarize_sheet.dart` to merge checked states from `widget.initialSummary` using `preserveCheckedItems` when loading session messages, and update RAM (`_chatMessages`) and DB when merged.
- [x] Task 224.3: Ensure `onChanged` in `ai_summarize_sheet.dart` syncs updated summary text to RAM & DB immediately when checkboxes are toggled (creating AI message in RAM/DB if none exists yet).
- [x] Task 224.4: Perform static analysis (`flutter analyze`).

### Task 224.1: Update unchecked checkbox styling in markdown_block_editor.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Update line 943 to use `GlassColors.onSurfaceVariant.withOpacity(0.6)` for border color when `!block.isChecked` with `width: 1.5`, and line 948 to use `GlassColors.onSurfaceVariant.withOpacity(0.05)` for fill color when `!block.isChecked`.
- **Why:** Resolve user report that empty checkboxes `- [ ]` are faint and invisible ("มองไม่เห็นเลยมองยากมากพอไม่มีการติ๊ก").
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Empty checkboxes render with clear 1.5px border and subtle fill.

### Task 224.2: Update _loadCurrentSessionMessages() to preserve checked state on session load
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `_loadCurrentSessionMessages()`, load `newestAiMsg` (`msgs.where((m) => !m.isUser).firstOrNull`). If `widget.initialSummary` is present and non-empty and `newestAiMsg` exists, run `preserveCheckedItems(widget.initialSummary!, newestAiMsg.text)` to preserve checked items. Set `_summaryOutput` to this merged text, and if changed, update `_chatMessages` in RAM and sync to DB via `ApiCloudflare.insertChatMessage`.
- **Why:** Resolve user report that opening AI Summary sheet loads stale summary without latest checked boxes.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Sheet loads latest AI summary with checked items preserved.

### Task 224.3: Sync updated summary to RAM & DB on checkbox toggles in ai_summarize_sheet.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `MarkdownBlockEditor.onChanged` in `ai_summarize_sheet.dart`, update `_summaryOutput` and update/create AI message in `_chatMessages` RAM and call `ApiCloudflare.insertChatMessage` to persist to DB.
- **Why:** Ensure checkbox toggling in AI summary sheet immediately updates both RAM and Cloudflare DB.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Toggling checkbox updates RAM and DB immediately.

### Task 224.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run `flutter analyze` and confirm zero errors.
- **Why:** Maintain codebase health and compliance with Sovereign guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** Flutter analyze passes with 0 issues.
