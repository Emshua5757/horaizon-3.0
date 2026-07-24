import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';

class SduiShimmerLoader extends StatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;
  final Widget? child;

  const SduiShimmerLoader({
    super.key,
    required this.node,
    required this.dispatcher,
    this.child,
  });

  @override
  State<SduiShimmerLoader> createState() => _SduiShimmerLoaderState();
}

class _SduiShimmerLoaderState extends State<SduiShimmerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;

  // Behavior getters directly mapping to spec
  int get shimmerType => widget.node.behavior<int>(91) ?? 0;
  int get shimmerAnimStyle => widget.node.behavior<int>(92) ?? 0;
  int get lineCount => widget.node.behavior<int>(93) ?? 3;
  double get lastLineWidthPct => widget.node.behavior<double>(94) ?? widget.node.behavior<int>(94)?.toDouble() ?? 0.6;
  double? get maxHeight => widget.node.behavior<double>(37) ?? widget.node.behavior<int>(37)?.toDouble();
  double get borderRadius => widget.node.behavior<double>(21) ?? widget.node.behavior<int>(21)?.toDouble() ?? 8.0;
  EdgeInsetsGeometry get padding => SduiStyleResolver.resolveEdgeInsets(widget.node.behavior<dynamic>(30)) ?? EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: shimmerAnimStyle == 0); // Fade reverses, Sweep loops forward

    _opacityAnim = Tween<double>(begin: 0.2, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, Color baseColor) {
    Widget animated;
    if (shimmerAnimStyle == 1) {
      // Linear Sweep using smooth alignment translations (no stop clamping)
      animated = AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          final t = _controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-2.0 + (t * 4.0), -0.2),
              end: Alignment(0.0 + (t * 4.0), 0.2),
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.75),
                Colors.white.withValues(alpha: 0.35),
                baseColor.withValues(alpha: 0.75),
                baseColor,
              ],
              stops: const [
                0.1,
                0.35,
                0.5,
                0.65,
                0.9,
              ],
            ).createShader(bounds),
            child: child,
          );
        },
      );
    } else {
      // Fade Pulse
      animated = FadeTransition(opacity: _opacityAnim, child: child);
    }
    return RepaintBoundary(child: animated);
  }

  Widget _rect(Color color, {double? height, double radius = 8.0, double widthFactor = 1.0}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height ?? 16.0,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _circle(Color color, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildRectangle(Color c) => _rect(c, height: maxHeight ?? 40.0, radius: borderRadius);
  Widget _buildCircle(Color c) => _circle(c, maxHeight ?? 48.0);
  
  Widget _buildParagraph(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lineCount, (i) {
        final isLast = i == lineCount - 1;
        return Padding(
          padding: i == 0 ? EdgeInsets.zero : const EdgeInsets.only(top: 6.0),
          child: _rect(c, height: 14.0, radius: 4.0, widthFactor: isLast ? lastLineWidthPct : 1.0),
        );
      }),
    );
  }

  Widget _buildListTile(Color c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _circle(c, 44.0),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _rect(c, height: 14.0, radius: 4.0),
              const SizedBox(height: 8.0),
              _rect(c, height: 12.0, radius: 4.0, widthFactor: 0.65),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _rect(c, height: maxHeight ?? 180.0, radius: borderRadius),
        const SizedBox(height: 12.0),
        _buildListTile(c),
      ],
    );
  }

  Widget _buildChatBubble(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _rect(c, height: 14.0, radius: 12.0),
        const SizedBox(height: 6.0),
        _rect(c, height: 14.0, radius: 12.0, widthFactor: 0.7),
        const SizedBox(height: 6.0),
        _rect(c, height: 14.0, radius: 12.0, widthFactor: 0.45),
      ],
    );
  }

  Widget _buildStatCard(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _rect(c, height: maxHeight ?? 48.0, radius: borderRadius, widthFactor: 0.55),
        const SizedBox(height: 8.0),
        _rect(c, height: 12.0, radius: 4.0, widthFactor: 0.35),
      ],
    );
  }

  Widget _buildFeedRow(Color c) {
    return Row(
      children: [
        Expanded(flex: 3, child: _rect(c, height: 18.0, radius: 4.0)),
        const SizedBox(width: 8.0),
        Expanded(flex: 2, child: _rect(c, height: 18.0, radius: 4.0)),
        const SizedBox(width: 8.0),
        Expanded(flex: 1, child: _rect(c, height: 18.0, radius: 4.0)),
      ],
    );
  }

  Widget _buildModuleCard(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circle(c, 32.0),
            Container(
              width: 60.0,
              height: 14.0,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 140.0,
          height: 18.0,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        const SizedBox(height: 2.0),
        Container(
          width: 80.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalWindow(Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18.0,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _circle(c, 6.0),
              const SizedBox(width: 4.0),
              _circle(c, 6.0),
              const SizedBox(width: 4.0),
              _circle(c, 6.0),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: 110.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: 200.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final Color baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget body;
    if (widget.child != null) {
      body = widget.child!;
    } else {
      switch (shimmerType) {
        case 1: body = _buildCircle(baseColor); break;
        case 2: body = _buildParagraph(baseColor); break;
        case 3: body = _buildListTile(baseColor); break;
        case 4: body = _buildMediaCard(baseColor); break;
        case 5: body = _buildChatBubble(baseColor); break;
        case 6: body = _buildStatCard(baseColor); break;
        case 7: body = _buildFeedRow(baseColor); break;
        case 8: body = _buildModuleCard(baseColor); break;
        case 9: body = _buildTerminalWindow(baseColor); break;
        default: body = _buildRectangle(baseColor); break;
      }
    }

    final animated = _animated(body, baseColor);
    final pad = padding;
    if (pad != EdgeInsets.zero) {
      return Padding(padding: pad, child: animated);
    }
    return animated;
  }

}
