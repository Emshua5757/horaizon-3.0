import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// The Universal Layout Box — SDUI-4 Composite Primitive (Type ID 6).
///
/// Absorbs the responsibilities of V3's separate Row, Column, Stack, Card,
/// SizedBox, and Padding primitives into a single data-driven widget.
///
/// ## Behavior Key Reference (schema-sdui4.md)
/// **Layout:**
///   - 10: layout_direction — 0=Column, 1=Row, 2=Stack
///   - 11: main_axis_alignment — 0=start, 1=end, 2=center, 3=spaceBetween, 4=spaceAround, 5=spaceEvenly
///   - 12: cross_axis_alignment — 0=start, 1=end, 2=center, 6=stretch, 7=baseline
///   - 13: main_axis_size — 0=min, 1=max
///   - 14: flex — int weight (wraps self in Expanded if parent is flex)
///   - 15: overflow — 0=visible, 1=clip, 2=scroll (wraps in SingleChildScrollView)
///
/// **Visual:**
///   - 20: background_color — token or ARGB
///   - 21: border_radius — double (symmetric)
///   - 22: border_width — double
///   - 23: border_color — token or ARGB
///   - 24: shadow_elevation — 0.0–24.0
///   - 25: shadow_color — token or ARGB
///   - 26: clip_behavior — 0=none, 1=antiAlias, 2=hardEdge
///   - 27: opacity — 0.0–1.0
///
/// **Dimensions:**
///   - 30: padding — double or [h,v] or [t,r,b,l]
///   - 31: margin — double or [h,v] or [t,r,b,l]
///   - 32: width — double or "infinity"
///   - 33: height — double or "infinity"
///   - 34: min_width, 35: max_width, 36: min_height, 37: max_height
///   - 38: aspect_ratio — double
///
/// **Animation:**
///   - 80: mount_anim — 0=none, 1=fade_in, 2=slide_up, 3=slide_down, 4=scale_in
///   - 82: anim_duration_ms — int
///   - 83: anim_curve — 0=linear, 1=easeIn, 2=easeOut, 3=easeInOut, 4=bounceOut
class SduiContainer extends StatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiContainer({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  State<SduiContainer> createState() => _SduiContainerState();
}

class _SduiContainerState extends State<SduiContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _setupMountAnimation();
  }

  void _setupMountAnimation() {
    final raw80 = widget.node.behaviors[80];
    final int mountAnim = raw80 is num ? raw80.toInt() : 0;
    if (mountAnim == 0) return;

    final raw82 = widget.node.behaviors[82];
    final int durationMs = raw82 is num ? raw82.toInt() : 350;
    final raw83 = widget.node.behaviors[83];
    final int curveId = raw83 is num ? raw83.toInt() : 3;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    final Curve curve = _resolveCurve(curveId);
    _animation = CurvedAnimation(parent: _animController!, curve: curve);
    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  // ── Enum Resolution Jump Tables (O(1)) ────────────────────────────────────

  static MainAxisAlignment _resolveMainAxis(int? id) => switch (id) {
    1 => MainAxisAlignment.end,
    2 => MainAxisAlignment.center,
    3 => MainAxisAlignment.spaceBetween,
    4 => MainAxisAlignment.spaceAround,
    5 => MainAxisAlignment.spaceEvenly,
    _ => MainAxisAlignment.start,
  };

  static CrossAxisAlignment _resolveCrossAxis(int? id) => switch (id) {
    1 => CrossAxisAlignment.end,
    2 => CrossAxisAlignment.center,
    6 => CrossAxisAlignment.stretch,
    7 => CrossAxisAlignment.baseline,
    _ => CrossAxisAlignment.start,
  };

  static MainAxisSize _resolveMainAxisSize(int? id) => switch (id) {
    0 => MainAxisSize.min,
    _ => MainAxisSize.max,
  };

  static Clip _resolveClip(int? id) => switch (id) {
    1 => Clip.antiAlias,
    2 => Clip.hardEdge,
    _ => Clip.none,
  };

  static Curve _resolveCurve(int id) => switch (id) {
    1 => Curves.easeIn,
    2 => Curves.easeOut,
    4 => Curves.bounceOut,
    _ => Curves.easeInOut,
  };

  static double? _resolveSize(dynamic raw) {
    if (raw == null) return null;
    if (raw == 'infinity' || raw == double.infinity) return double.infinity;
    if (raw is num) return raw.toDouble();
    return null;
  }

  /// Safely reads a numeric behavior key regardless of whether the JSON
  /// payload stored it as an [int] or a [double]. Direct `as int?` casts
  /// on a double value throw a TypeError at runtime — this prevents that.
  double? _num(int key) {
    final raw = widget.node.behaviors[key];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return null;
  }

  // ── Layout Children Builder ───────────────────────────────────────────────

  List<Widget> _buildChildren(bool isFlexLayout) {
    final children = widget.node.children ?? [];
    return children.map((childNode) {
      // Each child gets the SduiFlexContext that says "yes, your parent is flex"
      // so the child can safely wrap itself in Expanded if its flex(14) key is set.
      return SduiFlexContext(
        isFlexParent: isFlexLayout,
        child: SduiRenderer(node: childNode, dispatcher: widget.dispatcher),
      );
    }).toList();
  }

  /// Builds a [ReorderableListView] when behavior key 86 (reorderable) == 1.
  ///
  /// Each block wrapper child is identified by [SduiNode.id] as its [Key].
  /// The drag handle Button (typeId=3, action_type=8) is wrapped in
  /// [ReorderableDragStartListener] so only the ≡ icon initiates a drag.
  ///
  /// On drag-end [onReorder] receives the old/new indices. We:
  ///   1. Optimistically mutate the local children list in-place (O(1) swap).
  ///   2. Extract neighbor node IDs from the updated list.
  ///   3. Fire RPC 110 (reorder_block) with {block_id, before_block_id, after_block_id}.
  ///
  /// Node.js computes the new lexo_rank from neighbor IDs — Flutter stays
  /// completely agnostic to shua_diary's ordering scheme.
  Widget _buildReorderableList() {
    // Read children as a mutable list so we can splice on reorder.
    final children = List<SduiNode>.from(widget.node.children ?? []);
    final rpcMethodId = _int(87, 110); // behavior key 87 = reorder RPC ID

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          buildDefaultDragHandles: false,
          onReorderItem: (int oldIndex, int newIndex) {
            setInnerState(() {
              final moved = children.removeAt(oldIndex);
              children.insert(newIndex, moved);
            });

            // Extract block_id from the wrapper node id:
            // Format: "diary_editor_{entryId}:block_{blockId}:wrapper"
            final movedNode = children[newIndex];
            final movedBlockId = _extractBlockId(movedNode.id);
            if (movedBlockId == null) return;

            final beforeId = newIndex > 0
                ? _extractBlockId(children[newIndex - 1].id)
                : null;
            final afterId = newIndex < children.length - 1
                ? _extractBlockId(children[newIndex + 1].id)
                : null;

            gLog.log(
              HbpLogLevel.INFO,
              'SDUI_REORDER',
              'block=$movedBlockId before=$beforeId after=$afterId',
              tags: HbpLogTag.SDUI,
              telemetry: {
                'block_id': movedBlockId,
                'before_id': beforeId,
                'after_id': afterId,
              },
            );

            // Fire RPC — server computes lexo_rank from neighbors
            widget.dispatcher.onReorder(
              rpcMethodId,
              movedBlockId,
              beforeId,
              afterId,
            );
          },
          itemBuilder: (context, index) {
            final childNode = children[index];
            // Find the drag handle child node (the first Button child of the wrapper)
            final dragHandleIndex = _findDragHandleIndex(childNode);
            return _buildReorderableItem(
              context,
              index,
              childNode,
              dragHandleIndex,
            );
          },
        );
      },
    );
  }

  Widget _buildReorderableItem(
    BuildContext context,
    int index,
    SduiNode wrapperNode,
    int dragHandleChildIndex,
  ) {
    final wrapperChildren = wrapperNode.children ?? [];
    return KeyedSubtree(
      key: ValueKey(wrapperNode.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < wrapperChildren.length; i++)
            if (i == dragHandleChildIndex)
              ReorderableDragStartListener(
                index: index,
                child: SduiFlexContext(
                  isFlexParent: true,
                  child: SduiRenderer(
                    node: wrapperChildren[i],
                    dispatcher: widget.dispatcher,
                  ),
                ),
              )
            else
              SduiFlexContext(
                isFlexParent: true,
                child: SduiRenderer(
                  node: wrapperChildren[i],
                  dispatcher: widget.dispatcher,
                ),
              ),
        ],
      ),
    );
  }

  /// Finds the index of the drag handle child within a wrapper node.
  /// The drag handle Button has action_type == 8 in its action_payload.
  int _findDragHandleIndex(SduiNode wrapperNode) {
    final kids = wrapperNode.children ?? [];
    for (int i = 0; i < kids.length; i++) {
      final child = kids[i];
      if (child.typeId == 3) {
        // Button — check action_payload action type
        final actionPayload = child.behaviors[70];
        if (actionPayload is Map) {
          final actionType = actionPayload[0];
          if (actionType == 8) return i;
        }
      }
    }
    return 0; // Fallback: first child is drag handle
  }

  /// Extracts the block_id segment from a node ID of the form:
  ///   "diary_editor_{entryId}:block_{blockId}:wrapper"
  /// Returns null if the pattern doesn't match.
  static String? _extractBlockId(String nodeId) {
    final blockSegment = nodeId
        .split(':')
        .firstWhere((s) => s.startsWith('block_'), orElse: () => '');
    if (blockSegment.isEmpty) return null;
    return blockSegment.replaceFirst('block_', '');
  }


  // ── Core Widget Assembly ──────────────────────────────────────────────────

  int _int(int key, [int fallback = 0]) {
    final raw = widget.node.behaviors[key];
    return raw is num ? raw.toInt() : fallback;
  }

  Widget _buildLayout() {
    final int direction = _int(10);
    final int overflow = _int(15);

    // ── Reorderable mode (behavior key 86 == 1) ──────────────────────────────
    // When set, children are rendered in a ReorderableListView instead of Column.
    // The drag handle button (action_type=8) triggers the drag gesture.
    if (_int(86) == 1) {
      return _buildReorderableList();
    }

    final mainAxisAlign = _resolveMainAxis(_int(11));
    final crossAxisAlign = _resolveCrossAxis(_int(12));
    final mainAxisSize = _resolveMainAxisSize(_int(13));

    if (direction == 2) {
      // ── Stack ─────────────────────────────────────────────────────────────
      return Stack(children: _buildChildren(false));
    }

    // ── Row / Column with layout constraint safety checks ─────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        if (direction == 1) {
          // Row layout
          final hasBoundedWidth = constraints.hasBoundedWidth;
          final hasBoundedHeight = constraints.hasBoundedHeight;
          final crossAlign = crossAxisAlign == CrossAxisAlignment.stretch
              ? (hasBoundedHeight ? CrossAxisAlignment.stretch : CrossAxisAlignment.start)
              : crossAxisAlign;

          Widget row = Row(
            mainAxisAlignment: mainAxisAlign,
            crossAxisAlignment: crossAlign,
            mainAxisSize: mainAxisSize,
            children: _buildChildren(hasBoundedWidth), // Flex is only valid if width is bounded
          );

          if (overflow == 2) {
            row = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            );
          }
          return row;
        } else {
          // Column layout
          final hasBoundedHeight = constraints.hasBoundedHeight;
          final hasBoundedWidth = constraints.hasBoundedWidth;
          final crossAlign = crossAxisAlign == CrossAxisAlignment.stretch
              ? (hasBoundedWidth ? CrossAxisAlignment.stretch : CrossAxisAlignment.start)
              : crossAxisAlign;

          Widget col = Column(
            mainAxisAlignment: mainAxisAlign,
            crossAxisAlignment: crossAlign,
            mainAxisSize: mainAxisSize,
            children: _buildChildren(hasBoundedHeight), // Flex is only valid if height is bounded
          );

          if (overflow == 2) {
            col = SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: col,
            );
          }
          return col;
        }
      },
    );
  }

  Widget _wrapDecoration(Widget child) {
    final Color? bgColor = SduiStyleResolver.resolveColor(context, _int(20));
    final double? borderRadius = _num(21);
    final double? borderWidth = _num(22);
    final Color? borderColor = SduiStyleResolver.resolveColor(
      context,
      _int(23),
    );
    final double? elevation = _num(24);
    final Color? shadowColor = SduiStyleResolver.resolveColor(
      context,
      _int(25),
    );
    final Clip clipBehavior = _resolveClip(_int(26));

    // Dimension keys — _resolveSize handles 'infinity' string + num
    final double? width = _resolveSize(widget.node.behaviors[32]);
    final double? height = _resolveSize(widget.node.behaviors[33]);
    final double? minWidth = _resolveSize(widget.node.behaviors[34]);
    final double? maxWidth = _resolveSize(widget.node.behaviors[35]);
    final double? minHeight = _resolveSize(widget.node.behaviors[36]);
    final double? maxHeight = _resolveSize(widget.node.behaviors[37]);
    final double? aspectRatio = _num(38);

    final EdgeInsetsGeometry? padding = SduiStyleResolver.resolveEdgeInsets(
      widget.node.behaviors[30],
    );
    final EdgeInsetsGeometry? margin = SduiStyleResolver.resolveEdgeInsets(
      widget.node.behaviors[31],
    );

    // Build BoxDecoration
    final List<BoxShadow>? boxShadows = elevation != null && elevation > 0
        ? [
            BoxShadow(
              color:
                  shadowColor ??
                  Theme.of(context).colorScheme.shadow.withAlpha(80),
              blurRadius: elevation * 2,
              spreadRadius: elevation * 0.25,
              offset: Offset(0, elevation * 0.5),
            ),
          ]
        : null;

    final BoxDecoration? decoration =
        (bgColor != null ||
            borderRadius != null ||
            borderWidth != null ||
            boxShadows != null)
        ? BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius != null && borderRadius > 0
                ? BorderRadius.circular(borderRadius)
                : null,
            border:
                borderWidth != null && borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
            boxShadow: boxShadows,
          )
        : null;

    Widget result = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      clipBehavior: decoration != null ? clipBehavior : Clip.none,
      decoration: decoration,
      child: child,
    );

    // Wrap in ConstrainedBox if min/max bounds are set
    if (minWidth != null ||
        maxWidth != null ||
        minHeight != null ||
        maxHeight != null) {
      result = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          maxWidth: maxWidth ?? double.infinity,
          minHeight: minHeight ?? 0.0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: result,
      );
    }

    // Wrap in AspectRatio if set
    if (aspectRatio != null && aspectRatio > 0) {
      result = AspectRatio(aspectRatio: aspectRatio, child: result);
    }

    return result;
  }

  Widget _wrapOpacity(Widget child) {
    final double? opacity = _num(27);
    if (opacity != null && opacity < 1.0) {
      return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
    }
    return child;
  }

  Widget _wrapAnimation(Widget child) {
    final raw80 = widget.node.behaviors[80];
    final int mountAnim = raw80 is num ? raw80.toInt() : 0;
    if (mountAnim == 0 || _animation == null) return child;

    return switch (mountAnim) {
      1 => FadeTransition(opacity: _animation!, child: child),
      2 => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_animation!),
        child: FadeTransition(opacity: _animation!, child: child),
      ),
      3 => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(_animation!),
        child: FadeTransition(opacity: _animation!, child: child),
      ),
      4 => ScaleTransition(scale: _animation!, child: child),
      _ => child,
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget core = _buildLayout();
    core = _wrapDecoration(core);
    core = _wrapOpacity(core);
    core = _wrapAnimation(core);
    return core;
  }
}
