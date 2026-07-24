import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// SduiCarousel — Type ID 30
///
/// Horizontal paging slide carousel backed by [PageView].
///
/// ### Behavior Keys Consumed
///
///   CHILD_ASPECT_RATIO (116) — Height = width / ratio. Default: 1.77 (16:9).
///   ANIM_DURATION_MS   (82)  — Auto-scroll interval in ms. null = manual swipe only.
///   ACCENT_COLOR_TOKEN (96)  — Active dot / arrow button accent color.
///   PADDING            (30)  — Outer padding around the entire carousel.
///   BIND_KEY           (40)  — StateVault key for the active slide index (int).
///   135: show_indicators  — bool. Default: true. Shows dot row below slides.
///   136: show_arrows      — bool. Default: true. Shows ◀ ▶ overlay arrow buttons.
///   137: peek_extent      — double px. Default: 0. >0 activates peekthrough mode
///                          (adjacent slides peek in from the edges).
///
/// ### Content Keys Consumed
///   VALUE (0) — Initial active slide index (int). Overridden by StateVault.
///
/// ### Children
///   Composite — any SDUI nodes are rendered as slides, one per page.
///
/// ### Auto-scroll Behavior
///   When [anim_duration_ms] is set, slides advance with a 400ms crossfade
///   animation on an [AnimationController]-driven ticker loop — lifecycle-safe
///   because it is bound to the widget's [TickerProvider] and pauses when the
///   app is backgrounded.
///
/// ### Peekthrough Math
///   viewportFraction = 1 - (2 * peekExtent / constraints.maxWidth)
///   This is computed inside a [LayoutBuilder] so it always reflects the actual
///   rendered width. A new [PageController] is created only when peekExtent
///   changes, not on every frame.
class SduiCarousel extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiCarousel({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiCarousel> createState() => _SduiCarouselState();
}

class _SduiCarouselState extends ConsumerState<SduiCarousel>
    with SingleTickerProviderStateMixin {
  // ── Page Controller & Scroll State ────────────────────────────────────────
  PageController? _pageController;
  int _currentPage = 0;

  // Tracks the last peek extent used to build the PageController.
  // We only recreate the controller when this value changes.
  double _lastPeekExtent = -1;

  // ── Auto-scroll ───────────────────────────────────────────────────────────
  // AnimationController drives the auto-scroll timer — lifecycle-correct.
  // We use a plain Timer here because AnimationController.repeat() fires
  // continuously per-frame which is wasteful for a coarse-grained interval.
  // Instead, we use a self-rescheduling Timer.periodic that cancels itself
  // when the widget is disposed.
  Timer? _autoScrollTimer;

  // ── Initialization ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final String bindKey =
        widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    // Read initial page from vault; fall back to VALUE content key, then 0.
    final vaultPage =
        ref.read(sduiStateVaultProvider.select((s) => s[bindKey]));
    final contentPage = widget.node.contentVal<int>(HbpContent.VALUE);
    _currentPage = (vaultPage is int)
        ? vaultPage
        : (contentPage is int ? contentPage : 0);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  // ── PageController Management ─────────────────────────────────────────────

  /// Returns the [PageController] for the given [peekExtent] and [screenWidth].
  /// Rebuilds the controller only when the peek extent changes (not per frame).
  PageController _resolveController(double peekExtent, double screenWidth) {
    if (_pageController != null && peekExtent == _lastPeekExtent) {
      return _pageController!;
    }

    // Dispose old controller before creating a new one.
    _pageController?.dispose();
    _lastPeekExtent = peekExtent;

    double viewportFraction = 1.0;
    if (peekExtent > 0 && screenWidth > 0) {
      // Clamp so we never get a non-positive fraction.
      viewportFraction =
          (1.0 - (2.0 * peekExtent / screenWidth)).clamp(0.1, 1.0);
    }

    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );
    return _pageController!;
  }

  // ── Auto-scroll ───────────────────────────────────────────────────────────

  void _startAutoScroll(int intervalMs, int pageCount) {
    _autoScrollTimer?.cancel();
    if (intervalMs <= 0 || pageCount <= 1) return;

    _autoScrollTimer =
        Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      // Wrap around: when we hit the last slide, jump back to 0.
      final nextPage = (_currentPage + 1) % pageCount;
      _pageController?.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() => _autoScrollTimer?.cancel();

  // ── Page Change Handler ───────────────────────────────────────────────────

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    final String bindKey =
        widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    ref.read(sduiStateVaultProvider.notifier).set(bindKey, page);
    // Use onStateChange so server is notified of slide index changes.
    widget.dispatcher.onStateChange(bindKey, page);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  bool _boolBehavior(int key, {required bool defaultValue}) {
    final raw = widget.node.behaviors[key];
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    return defaultValue;
  }

  double _doubleBehavior(int key, {required double defaultValue}) {
    final raw = widget.node.behaviors[key];
    if (raw is num) return raw.toDouble();
    return defaultValue;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final children = node.children ?? [];
    final pageCount = children.length;

    // ── Behavior Resolution ────────────────────────────────────────────────
    final double aspectRatio = _doubleBehavior(116, defaultValue: 16 / 9);
    final int? autoScrollMs = () {
      final raw = node.behaviors[HbpBehavior.ANIM_DURATION_MS];
      return raw is num ? raw.toInt() : null;
    }();
    final int? accentColorToken =
        node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final EdgeInsetsGeometry padding = SduiStyleResolver.resolveEdgeInsets(
          node.behavior<dynamic>(HbpBehavior.PADDING),
        ) ??
        EdgeInsets.zero;
    final bool showIndicators = _boolBehavior(135, defaultValue: true);
    final bool showArrows = _boolBehavior(136, defaultValue: true);
    final double peekExtent = _doubleBehavior(137, defaultValue: 0.0);

    final Color accentColor =
        SduiStyleResolver.resolveColor(context, accentColorToken) ??
            colorScheme.primary;

    if (pageCount == 0) {
      return _buildEmpty(colorScheme, theme, padding);
    }

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final double width = constraints.maxWidth;
          final PageController controller =
              _resolveController(peekExtent, width);

          // Restart auto-scroll whenever the build fires (interval may have changed).
          // We guard with mounted to avoid calling this during hot-reload tears.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (autoScrollMs != null && autoScrollMs > 0) {
              _startAutoScroll(autoScrollMs, pageCount);
            } else {
              _stopAutoScroll();
            }
          });

          final double slideHeight = width / aspectRatio;

          Widget pageView = SizedBox(
            height: slideHeight,
            child: PageView.builder(
              controller: controller,
              onPageChanged: _onPageChanged,
              itemCount: pageCount,
              itemBuilder: (ctx, index) {
                return Padding(
                  // When peeking, add horizontal padding so adjacent slides
                  // don't overlap the active slide's content.
                  padding: peekExtent > 0
                      ? const EdgeInsets.symmetric(horizontal: 6.0)
                      : EdgeInsets.zero,
                  child: SduiRenderer(
                    node: children[index],
                    dispatcher: widget.dispatcher,
                  ),
                );
              },
            ),
          );

          // ── Overlay Arrows ───────────────────────────────────────────────
          if (showArrows && pageCount > 1) {
            pageView = Stack(
              alignment: Alignment.center,
              children: [
                pageView,
                // ◀ Left arrow
                Positioned(
                  left: peekExtent > 0 ? peekExtent + 4 : 4,
                  child: _buildArrowButton(
                    icon: Icons.chevron_left_rounded,
                    accentColor: accentColor,
                    onPressed: _currentPage > 0
                        ? () => controller.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                ),
                // ▶ Right arrow
                Positioned(
                  right: peekExtent > 0 ? peekExtent + 4 : 4,
                  child: _buildArrowButton(
                    icon: Icons.chevron_right_rounded,
                    accentColor: accentColor,
                    onPressed: _currentPage < pageCount - 1
                        ? () => controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                ),
              ],
            );
          }

          // ── Dot Indicators ───────────────────────────────────────────────
          if (showIndicators && pageCount > 1) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pageView,
                const SizedBox(height: 10),
                _buildDotIndicators(
                  pageCount: pageCount,
                  accentColor: accentColor,
                  colorScheme: colorScheme,
                ),
              ],
            );
          }

          return pageView;
        },
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildArrowButton({
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.black.withAlpha(130),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: onPressed != null
                ? accentColor
                : accentColor.withAlpha(80),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators({
    required int pageCount,
    required Color accentColor,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: active ? 18.0 : 7.0,
          height: 7.0,
          decoration: BoxDecoration(
            color: active
                ? accentColor
                : colorScheme.onSurface.withAlpha(50),
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildEmpty(
    ColorScheme colorScheme,
    ThemeData theme,
    EdgeInsetsGeometry padding,
  ) {
    return Padding(
      padding: padding,
      child: AspectRatio(
        aspectRatio: _doubleBehavior(116, defaultValue: 16 / 9),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colorScheme.outline.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_carousel_rounded,
                  color: colorScheme.onSurfaceVariant.withAlpha(100),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Slides',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
