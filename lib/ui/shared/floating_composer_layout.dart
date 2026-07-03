import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Lays out a scrollable message list with a composer that *floats* over the
/// bottom (preserving the elegant overlay look), while keeping the list's
/// bottom padding in sync with the composer's real height.
///
/// As the composer grows (e.g. a multi-line message) the measured height
/// increases and [listBuilder] is rebuilt with a larger `bottomInset`, so the
/// newest message is pushed up and never hidden behind the composer — this
/// works whether the on-screen keyboard is open or closed, because the height
/// is measured on every layout pass, not just on widget rebuilds.
class FloatingComposerLayout extends StatefulWidget {
  /// Builds the scrollable. Apply [bottomInset] as the list's bottom padding
  /// so its content clears the floating composer.
  final Widget Function(BuildContext context, double bottomInset) listBuilder;

  /// The floating composer (text field / join button / locked banner).
  final Widget composer;

  /// Extra breathing room between the last item and the composer.
  final double gap;

  /// Bottom inset used for the first frame, before the composer is measured.
  final double initialInset;

  const FloatingComposerLayout({
    Key? key,
    required this.listBuilder,
    required this.composer,
    this.gap = -24,
    this.initialInset = 96,
  }) : super(key: key);

  @override
  State<FloatingComposerLayout> createState() => _FloatingComposerLayoutState();
}

class _FloatingComposerLayoutState extends State<FloatingComposerLayout> {
  late double _composerHeight = widget.initialInset;

  void _onSizeChange(Size size) {
    if (!mounted) return;
    if ((size.height - _composerHeight).abs() < 0.5) return;
    setState(() => _composerHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: widget.listBuilder(context, _composerHeight + widget.gap),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _MeasureSize(
            onChange: _onSizeChange,
            child: widget.composer,
          ),
        ),
      ],
    );
  }
}

/// Reports its child's size on every layout (even when the child relayouts
/// without the widget rebuilding — e.g. a TextField growing a line).
class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required Widget child})
      : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
      BuildContext context, _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    // Can't trigger a rebuild during layout — defer to after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
