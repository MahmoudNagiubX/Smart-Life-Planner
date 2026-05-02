import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_tokens.dart';
import '../../dashboard/widgets/quick_capture_sheet.dart';

// ── Layout constants matching Claude Design tokens ──────────────────────────
const double _kNavHeight = 62;
const double _kNavBottomMargin = 10;
const double _kNavSideMargin = 20;
const double _kFabSize = 52;
const double _kFabBorderWidth = 3;
// FAB protrudes this many px above nav pill top (matches tokens.css top:-22px)
const double _kFabOverhang = 16;

/// Total height of the bottomNavigationBar slot:
///   fab-overhang + nav-pill + bottom-margin + safeArea
double _totalHeight(double safeArea) =>
    _kFabOverhang + _kNavHeight + _kNavBottomMargin + safeArea;

// ── Tab definitions ──────────────────────────────────────────────────────────
class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String semantic;
  const _Tab(this.icon, this.activeIcon, this.label, this.semantic);
}

const _kTabs = [
  _Tab(Icons.home_outlined, Icons.home_rounded, 'Home', 'Go to Home'),
  _Tab(Icons.task_alt_outlined, Icons.task_alt, 'Tasks', 'Go to Tasks'),
  _Tab(Icons.timer_outlined, Icons.timer_rounded, 'Focus', 'Go to Focus'),
  _Tab(
    Icons.nightlight_round,
    Icons.nightlight_round,
    'Prayer',
    'Go to Prayer',
  ),
  _Tab(Icons.person_outline, Icons.person_rounded, 'Profile', 'Go to Profile'),
];

/// Floating pill navigation bar with center FAB.
///
/// Drop this into `Scaffold.bottomNavigationBar`. The parent Scaffold should
/// NOT use `extendBody`; the content area is correctly bounded above this
/// widget's allocated height.
class FloatingNavBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  ConsumerState<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends ConsumerState<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  bool _fabPressed = false;

  void _onFabTap() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickCaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding.bottom;
    final totalH = _totalHeight(safeArea);

    final navBg = AppColors.bgSurface.withValues(alpha: 0.92);
    final borderC = Colors.white.withValues(alpha: 0.78);
    final activeC = AppColors.brandPrimary;
    final inactiveC = AppColors.textBody;

    // FAB bottom (from container bottom):
    //   nav_top_from_bottom - fab_overhang + fab_height
    //   = (kNavBottomMargin + safeArea + kNavHeight) - kFabOverhang + kFabSize
    //   Wait — use bottom of container coordinate:
    //   nav_pill bottom = kNavBottomMargin + safeArea
    //   nav_pill top    = kNavBottomMargin + safeArea + kNavHeight
    //   fab top         = nav_pill top - kFabOverhang (i.e., kFabOverhang px above pill)
    //   fab bottom      = fab top + kFabSize
    //
    //   In Positioned.bottom (distance of child's BOTTOM EDGE from parent's BOTTOM):
    //     fab_bottom_from_parent_bottom = totalH - (kFabOverhang + kFabSize)
    //                                   = totalH - kFabOverhang - kFabSize
    // Simplified: fab_positioned_bottom = kNavBottomMargin + safeArea + kNavHeight - kFabSize + kFabOverhang... let me just compute directly.
    //
    // totalH = kFabOverhang + kNavHeight + kNavBottomMargin + safeArea
    // fab top from PARENT TOP = 0 (FAB sits at very top of container, touching it)
    // fab bottom from PARENT TOP = kFabSize
    // fab bottom from PARENT BOTTOM = totalH - kFabSize
    final fabBottomFromParent = totalH - _kFabSize;

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Pill nav ─────────────────────────────────────────────────────
          Positioned(
            left: _kNavSideMargin,
            right: _kNavSideMargin,
            bottom: _kNavBottomMargin + safeArea,
            height: _kNavHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl3),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: navBg,
                    borderRadius: BorderRadius.circular(AppRadius.xl2),
                    border: Border.all(color: borderC),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textHeading.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left group: Home (0), Tasks (1) — equal halves of nav
                      Expanded(
                        child: Row(
                          children: [
                            for (int i = 0; i < 2; i++)
                              Expanded(
                                child: _NavTabItem(
                                  tab: _kTabs[i],
                                  isActive: widget.currentIndex == i,
                                  activeColor: activeC,
                                  inactiveColor: inactiveC,
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Center FAB reserved slot — matches FAB width exactly
                      const SizedBox(width: _kFabSize + 20),
                      // Right group: Focus (2), Prayer (3), Profile (4)
                      Expanded(
                        child: Row(
                          children: [
                            for (int i = 2; i < _kTabs.length; i++)
                              Expanded(
                                child: _NavTabItem(
                                  tab: _kTabs[i],
                                  isActive: widget.currentIndex == i,
                                  activeColor: activeC,
                                  inactiveColor: inactiveC,
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: _kNavBottomMargin + safeArea + _kNavHeight - 1,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: _kFabSize + 14,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.bgApp.withValues(alpha: 0),
                        AppColors.bgApp.withValues(alpha: 0.80),
                        AppColors.bgApp.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── FAB ───────────────────────────────────────────────────────────
          Positioned(
            bottom: fabBottomFromParent,
            left: 0,
            right: 0,
            height: _kFabSize,
            child: Center(
              child: Semantics(
                label: 'Quick capture — add task, note, or reminder',
                button: true,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _fabPressed = true),
                  onTapUp: (_) {
                    setState(() => _fabPressed = false);
                    _onFabTap();
                  },
                  onTapCancel: () => setState(() => _fabPressed = false),
                  child: AnimatedScale(
                    scale: _fabPressed ? 0.91 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: Container(
                      width: _kFabSize,
                      height: _kFabSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.action,
                        border: Border.all(
                          color: Colors.white,
                          width: _kFabBorderWidth,
                        ),
                        boxShadow: [
                          ...AppShadows.glowPurple,
                          BoxShadow(
                            color: AppColors.brandPink.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single tab item ──────────────────────────────────────────────────────────

class _NavTabItem extends StatelessWidget {
  final _Tab tab;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.tab,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tab.semantic,
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        splashColor: activeColor.withValues(alpha: 0.10),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: _kNavHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 28,
                decoration: BoxDecoration(
                  gradient: isActive ? AppGradients.action : null,
                  color: isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      key: ValueKey(isActive),
                      size: 21,
                      color: isActive ? Colors.white : inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? activeColor : inactiveColor,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1.0 : 0.0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
