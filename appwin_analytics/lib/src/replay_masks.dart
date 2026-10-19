/// Session replay masking for what Flutter draws (ADR-0057).
///
/// The native recorder captures the screen, but Flutter paints every widget
/// into one surface: the native masker cannot tell a text field from a
/// button in there. This walks the render tree and hands the native side the
/// rectangles to paint over.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Hides [child] in session replays, whatever the project's replay settings.
///
/// ```dart
/// AppwinMask(child: Text(user.iban))
/// ```
class AppwinMask extends SingleChildRenderObjectWidget {
  /// Masks [child] and everything inside it.
  const AppwinMask({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReplayFlag(mask: true);
}

/// Shows [child] in session replays even when the project masks all text or
/// all images. Text fields inside stay masked, always.
class AppwinUnmask extends SingleChildRenderObjectWidget {
  /// Lifts the text and image rules for [child] and everything inside it.
  const AppwinUnmask({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReplayFlag(mask: false);
}

/// Render object of [AppwinMask] and [AppwinUnmask]: a pass-through the
/// replay walk recognizes.
class _RenderReplayFlag extends RenderProxyBox {
  _RenderReplayFlag({required this.mask});

  /// `true` for [AppwinMask], `false` for [AppwinUnmask].
  final bool mask;
}

/// The project's session replay settings, as the native recorder applies
/// them. Part of the `AppwinAnalyticsPlatform` contract: an implementation
/// returns it from `replayMaskRules()`.
///
/// Text fields are masked whatever these say.
@immutable
class ReplayMaskRules {
  /// Rules as read from the native recorder.
  const ReplayMaskRules({
    required this.maskAllText,
    required this.maskAllImages,
    this.captureFrames = false,
  });

  /// Masks every text, not only text fields.
  final bool maskAllText;

  /// Masks every image.
  final bool maskAllImages;

  /// The native recorder takes the frames Flutter renders itself
  /// (`setReplayFrame`) rather than capturing the screen: on iOS, the native
  /// capture holds the main thread while the engine renders it again.
  final bool captureFrames;

  @override
  bool operator ==(Object other) =>
      other is ReplayMaskRules &&
      other.maskAllText == maskAllText &&
      other.maskAllImages == maskAllImages &&
      other.captureFrames == captureFrames;

  @override
  int get hashCode => Object.hash(maskAllText, maskAllImages, captureFrames);
}

/// The rectangles to paint over in [view], in logical pixels of the view,
/// clipped to what is painted on screen.
///
/// Text fields always; texts with [ReplayMaskRules.maskAllText]; images with
/// [ReplayMaskRules.maskAllImages]; every [AppwinMask]. [AppwinUnmask] lifts
/// the text and image rules below it, never the input one.
List<Rect> collectReplayMasks(RenderView view, ReplayMaskRules rules) {
  final out = <Rect>[];
  final child = view.child;
  // The view's own transform is the device pixel ratio: left out, so the
  // rects stay in logical pixels like `localToGlobal`.
  if (child != null) {
    _walk(child, Matrix4.identity(), Offset.zero & view.size, false, rules, out);
  }
  return out;
}

void _walk(
  RenderObject node,
  Matrix4 transform,
  Rect clip,
  bool unmasked,
  ReplayMaskRules rules,
  List<Rect> out,
) {
  final bounds = MatrixUtils.transformRect(transform, node.paintBounds).intersect(clip);
  final visible = bounds.width > 0 && bounds.height > 0;

  if (node is RenderEditable && !node.readOnly) {
    if (visible) out.add(bounds);
    return;
  }
  if (node is _RenderReplayFlag) {
    if (node.mask) {
      if (visible) out.add(bounds);
      return;
    }
    unmasked = true;
  }
  if (!unmasked && visible) {
    final isText = node is RenderParagraph || node is RenderEditable;
    if ((isText && rules.maskAllText) || (_isImage(node) && rules.maskAllImages)) {
      out.add(bounds);
    }
  }

  _visitPainted(node, (child) {
    var childClip = clip;
    final paintClip = node.describeApproximatePaintClip(child);
    if (paintClip != null) {
      childClip = clip.intersect(MatrixUtils.transformRect(transform, paintClip));
      if (childClip.width <= 0 || childClip.height <= 0) return;
    }
    final childTransform = transform.clone();
    node.applyPaintTransform(child, childTransform);
    _walk(child, childTransform, childClip, unmasked, rules, out);
  });
}

bool _isImage(RenderObject node) {
  if (node is RenderImage) return true;
  if (node is RenderDecoratedBox) {
    final decoration = node.decoration;
    return (decoration is BoxDecoration && decoration.image != null) ||
        (decoration is ShapeDecoration && decoration.image != null);
  }
  return false;
}

/// The children that get painted. The semantics walk already skips what is
/// offstage, invisible, behind an opaque route or scrolled away; but some
/// render objects also hide painted children from semantics, and those are
/// walked in full instead.
void _visitPainted(RenderObject node, RenderObjectVisitor visitor) {
  if (node is SemanticsAnnotationsMixin ||
      node is RenderExcludeSemantics ||
      node is RenderIgnorePointer ||
      node is RenderAbsorbPointer ||
      node is RenderSliverIgnorePointer) {
    node.visitChildren(visitor);
  } else {
    node.visitChildrenForSemantics(visitor);
  }
}
