import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DeferPointer extends StatelessWidget {
  const DeferPointer({
    super.key,
    required this.child,
    this.paintOnTop = false,
    this.link,
  });

  final Widget child;
  final bool paintOnTop;
  final DeferredPointerHandlerLink? link;

  @override
  Widget build(BuildContext context) {
    final effectiveLink = link ?? DeferredPointerHandler.of(context).link;
    return _DeferPointerRenderObjectWidget(
      link: effectiveLink,
      deferPaint: paintOnTop,
      child: child,
    );
  }
}

class _DeferPointerRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _DeferPointerRenderObjectWidget({
    required this.link,
    required this.deferPaint,
    required Widget child,
  }) : super(child: child);

  final DeferredPointerHandlerLink link;
  final bool deferPaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      DeferPointerRenderObject(link, deferPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    DeferPointerRenderObject renderObject,
  ) {
    renderObject.link = link;
    renderObject.deferPaint = deferPaint;
  }
}

class DeferPointerRenderObject extends RenderProxyBox {
  DeferPointerRenderObject(
    DeferredPointerHandlerLink link,
    this.deferPaint, {
    RenderBox? child,
  }) : super(child) {
    this.link = link;
  }

  bool deferPaint;
  bool _linked = false;

  late DeferredPointerHandlerLink _link;
  DeferredPointerHandlerLink get link => _link;
  set link(DeferredPointerHandlerLink link) {
    _link = link;
    link.add(this);
    _linked = true;
  }

  @override
  set child(RenderBox? child) {
    if (_linked) {
      link.remove(this);
      _linked = false;
    }
    super.child = child;
    if (this.child != null) {
      link.add(this);
      _linked = true;
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    link.add(this);
  }

  @override
  void detach() {
    link.remove(this);
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (deferPaint) return;
    context.paintChild(child!, offset);
  }

  @override
  void markNeedsPaint() {
    if (deferPaint) {
      _link.descendantNeedsPaint();
    } else {
      super.markNeedsPaint();
    }
  }
}

class DeferredPointerHandler extends StatefulWidget {
  const DeferredPointerHandler({
    super.key,
    required this.child,
    this.link,
  });

  final Widget child;
  final DeferredPointerHandlerLink? link;

  @override
  DeferredPointerHandlerState createState() => DeferredPointerHandlerState();

  static DeferredPointerHandlerState of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_InheritedDeferredPaintSurface>();
    assert(
      inherited != null,
      'DeferredPointerHandler was not found in the widget tree.',
    );
    return inherited!.state;
  }
}

class DeferredPointerHandlerState extends State<DeferredPointerHandler> {
  final DeferredPointerHandlerLink _link = DeferredPointerHandlerLink();
  DeferredPointerHandlerLink get link => _link;

  @override
  void didUpdateWidget(covariant DeferredPointerHandler oldWidget) {
    if (widget.link != null) {
      _link.removeAll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedDeferredPaintSurface(
      state: this,
      child: _DeferredHitTargetRenderObjectWidget(
        link: widget.link ?? _link,
        child: widget.child,
      ),
    );
  }
}

class _DeferredHitTargetRenderObjectWidget
    extends SingleChildRenderObjectWidget {
  const _DeferredHitTargetRenderObjectWidget({
    required this.link,
    super.child,
  });

  final DeferredPointerHandlerLink link;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _DeferredHitTargetRenderObject(link);

  @override
  void updateRenderObject(
    BuildContext context,
    _DeferredHitTargetRenderObject renderObject,
  ) {
    renderObject.link = link;
  }
}

class _DeferredHitTargetRenderObject extends RenderProxyBox {
  _DeferredHitTargetRenderObject(
    DeferredPointerHandlerLink link, [
    RenderBox? child,
  ]) : super(child) {
    this.link = link;
  }

  DeferredPointerHandlerLink? _link;
  DeferredPointerHandlerLink get link => _link!;
  set link(DeferredPointerHandlerLink link) {
    if (_link != null) {
      _link!.removeListener(markNeedsPaint);
    }
    _link = link;
    this.link.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    for (final painter in link.painters.reversed) {
      final hit = result.addWithPaintTransform(
        transform: painter.child!.getTransformTo(this),
        position: position,
        hitTest: (BoxHitTestResult result, Offset? position) {
          return painter.child!.hitTest(result, position: position!);
        },
      );
      if (hit) {
        return true;
      }
    }
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    for (final painter in link.painters) {
      if (painter.deferPaint == false) continue;
      context.paintChild(
        painter.child!,
        painter.child!.localToGlobal(Offset.zero, ancestor: this) + offset,
      );
    }
  }
}

class _InheritedDeferredPaintSurface extends InheritedWidget {
  const _InheritedDeferredPaintSurface({
    required super.child,
    required this.state,
  });

  final DeferredPointerHandlerState state;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class DeferredPointerHandlerLink extends ChangeNotifier {
  DeferredPointerHandlerLink();
  final List<DeferPointerRenderObject> _painters = [];

  void descendantNeedsPaint() => notifyListeners();

  List<DeferPointerRenderObject> get painters => List.unmodifiable(_painters);

  void add(DeferPointerRenderObject value) {
    if (!_painters.contains(value)) {
      _painters.add(value);
      notifyListeners();
    }
  }

  void remove(DeferPointerRenderObject value) {
    if (_painters.contains(value)) {
      _painters.remove(value);
      notifyListeners();
    }
  }

  void removeAll() {
    _painters.clear();
    notifyListeners();
  }
}
