import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Controls a Linux GtkWidget.
///
/// Typically created with [PlatformViewsService.initGtkView].
class GtkViewController extends GestureRecognitionPlatformViewController {
  GtkViewController._(
    this.id,
    TextDirection layoutDirection,
  ) : _layoutDirection = layoutDirection;

  /// Gtk's [GTK_TEXT_DIR_None](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkTextDirection) value.
  static const int kGtkTextDirectionNone = 0;

  /// Gtk's [GTK_TEXT_DIR_LTR](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkTextDirection) value.
  static const int kGtkTextDirectionLtr = 1;

  /// Gtk's [GTK_TEXT_DIR_RTL](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkTextDirection) value.
  static const int kGtkTextDirectionRtl = 2;

  /// The unique identifier of the Linux GtkWidget controlled by this controller.
  @override
  final int id;

  bool _debugDisposed = false;

  TextDirection _layoutDirection;

  static int _getGtkTextDirection(TextDirection direction) {
    switch (direction) {
      case TextDirection.ltr:
        return kGtkTextDirectionLtr;
      case TextDirection.rtl:
        return kGtkTextDirectionRtl;
    }
  }

  /// Sets the layout direction for the Linux GtkWidget.
  @override
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(!_debugDisposed,
        'trying to set a layout direction for a disposed Linux GtkWidget. View id: $id');

    if (layoutDirection == _layoutDirection) {
      return;
    }

    _layoutDirection = layoutDirection;

    final List<int> args = <int>[id, _getGtkTextDirection(layoutDirection)];
    return SystemChannels.platform_views.invokeMethod('setDirection', args);
  }

  /// Accepts an active gesture.
  ///
  /// When a touch sequence is happening on the embedded GtkWidget all touch events are delayed.
  /// Calling this method releases the delayed events to the embedded UIView and makes it consume
  /// any following touch events for the pointers involved in the active gesture.
  @override
  Future<void> acceptGesture(int pointer) {
    final List<int> args = <int>[id, pointer];
    return SystemChannels.platform_views.invokeMethod('acceptGesture', args);
  }

  /// Rejects an active gesture.
  ///
  /// When a touch sequence is happening on the embedded GtkWidget all touch events are delayed.
  /// Calling this method drops the buffered touch events and prevents any future touch events for
  /// the pointers that are part of the active touch sequence from arriving to the embedded view.
  @override
  Future<void> rejectGesture() {
    final List<int> args = <int>[id];
    return SystemChannels.platform_views.invokeMethod('rejectGesture', args);
  }

  /// Disposes the view.
  ///
  /// The [GtkViewController] object is unusable after calling this.
  /// The `id` of the platform view cannot be reused after the view is
  /// disposed.
  @override
  Future<void> dispose() async {
    _debugDisposed = true;
    await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
  }

  /// Notifies that a mouse pointer has entered into the embedded GtkWidget.
  ///
  /// Calling this method to distribute following motion events to the embedded GtkWidget.
  Future<void> enter() {
    final List<int> args = <int>[id];
    return SystemChannels.platform_views.invokeMethod('enter', args);
  }

  /// Notifies that a mouse pointer has exited from the embedded GtkWidget.
  ///
  /// Calling this method to stop distributing motion events to the embedded GtkWidget.
  Future<void> exit() {
    final List<int> args = <int>[id];
    return SystemChannels.platform_views.invokeMethod('exit', args);
  }
}

bool _factoryTypesSetEquals<T>(Set<Factory<T>>? a, Set<Factory<T>>? b) {
  if (a == b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return setEquals(_factoriesTypeSet(a), _factoriesTypeSet(b));
}

Set<Type> _factoriesTypeSet<T>(Set<Factory<T>> factories) {
  return factories.map<Type>((Factory<T> factory) => factory.type).toSet();
}

/// An interface for controlling a single platform view.
///
/// Used by [PlatformViewSurface] to interface with the platform view it embeds.
abstract class PlatformViewController {
  /// The viewId associated with this controller.
  ///
  /// The viewId should always be unique and non-negative.
  ///
  /// See also:
  ///
  ///  * [PlatformViewsRegistry], which is a helper for managing platform view IDs.
  int get viewId;

  /// Dispatches the `event` to the platform view.
  Future<void> dispatchPointerEvent(PointerEvent event);

  /// Disposes the platform view.
  ///
  /// The [PlatformViewController] is unusable after calling dispose.
  Future<void> dispose();

  /// Clears the view's focus on the platform side.
  Future<void> clearFocus();
}

/// An interface for controlling a platform view whose gestures passed from gesture
/// recognizer.
abstract class GestureRecognitionPlatformViewController {
  /// The viewId associated with this controller.
  ///
  /// The viewId should always be unqiue and non-negative. And it must not be null.
  ///
  /// See also:
  ///
  ///  * [PlatformViewsRegistry], which is a helper for managing platform view ids.
  int get id;

  /// Sets the layout direction for the platform view.
  Future<void> setLayoutDirection(TextDirection layoutDirection);

  /// Accepts an active gesture.
  ///
  /// When a touch sequence is happening on the embedded platform view, all touch
  /// events are delayed. Calling this method releases the delayed events to the
  /// embedded platform view and makes it consume any following touch events for
  /// the pointers involved in the active gesture.
  Future<void> acceptGesture(int pointer);

  /// Rejects an active gesture.
  ///
  /// When a touch seqeuence is happening on the embeeded platform view, all touch
  /// events are delays. Calling this method drops the buffered touch events and
  /// prevents any future touch events for the pointers that are part of the active
  /// touch sequence from arriving to the embedded view.
  Future<void> rejectGesture();

  /// Disposes the platform view.
  ///
  /// The [PlatformViewController] is unusable after calling dispose.
  /// The `id` of the platform view cannot be reused after the view is disposed.
  Future<void> dispose();
}

/// A render object for a platform view.
///
/// [_RenderGestureRecognitionPlatformView] is responsible for sizing and
/// displaying a platform view that accepts pointer events by a gesture
/// recognizer.
///
/// {@macro flutter.rendering.RenderAndroidView.layout}
///
/// {@macro flutter.rendering.RenderAndroidView.gestures}
abstract class _RenderGestureRecognitionPlatformView<
        ViewController extends GestureRecognitionPlatformViewController>
    extends RenderBox {
  /// Creates a render object for a platform view.
  ///
  /// The `viewId`, `hitTestBehavior`, and `gestureRecognizers` parameters must not be null.
  _RenderGestureRecognitionPlatformView({
    required ViewController viewController,
    required this.hitTestBehavior,
    required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : _viewController = viewController {
    updateGestureRecognizers(gestureRecognizers);
  }

  /// The unique identifier of the platform view controlled by this controller.
  ///
  /// Typically generated by [PlatformViewsRegistry.getNextPlatformViewId].
  ViewController get viewController => _viewController;
  ViewController _viewController;
  set viewController(ViewController viewController) {
    final bool needsSemanticsUpdate = _viewController.id != viewController.id;
    _viewController = viewController;
    markNeedsPaint();
    if (needsSemanticsUpdate) {
      markNeedsSemanticsUpdate();
    }
  }

  /// How to behave during hit testing.
  // The implicit setter is enough here as changing this value will just affect
  // any newly arriving events there's nothing we need to invalidate.
  PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.rendering.PlatformViewRenderBox.updateGestureRecognizers}
  void updateGestureRecognizers(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    assert(
      _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
      'There were multiple gesture recognizer factories for the same type, there must only be a single '
      'gesture recognizer factory for each gesture recognizer type.',
    );
    if (_factoryTypesSetEquals(
        gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer =
        _createGestureRecognizer(viewController, gestureRecognizers);
  }

  @protected
  _BypassPlatformViewGestureRecognizer _createGestureRecognizer(
      ViewController viewController,
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers);

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _BypassPlatformViewGestureRecognizer? _gestureRecognizer;

  PointerEvent? _lastPointerDownEvent;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.addLayer(PlatformViewLayer(
      rect: offset & size,
      viewId: _viewController.id,
    ));
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset? position}) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent ||
        !size.contains(position!)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) =>
      hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is! PointerDownEvent) {
      return;
    }
    _gestureRecognizer!.addPointer(event);
    _lastPointerDownEvent = event.original ?? event;
  }

  // This is registered as a global PointerRoute while the render object is attached.
  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    if (!(Offset.zero & size).contains(globalToLocal(event.position))) {
      return;
    }
    if ((event.original ?? event) != _lastPointerDownEvent) {
      // The pointer event is in the bounds of this render box, but we didn't get it in handleEvent.
      // This means that the pointer event was absorbed by a different render object.
      // Since on the platform side the FlutterTouchIntercepting view is seeing all events that are
      // within its bounds we need to tell it to reject the current touch sequence.
      _viewController.rejectGesture();
    }
    _lastPointerDownEvent = null;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.platformViewId = _viewController.id;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    GestureBinding.instance.pointerRouter
        .addGlobalRoute(_handleGlobalPointerEvent);
  }

  @override
  void detach() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointerEvent);
    _gestureRecognizer!.reset();
    super.detach();
  }
}

// This recognizer constructs gesture recognizers from a set of gesture recognizer factories
// it was give, adds all of them to a gesture arena team with the _BypassPlatformViewGestureRecognizer
// as the team captain.
// When the team wins a gesture the recognizer notifies the engine that it should release
// the touch sequence to the embedded platform view.
abstract class _BypassPlatformViewGestureRecognizer
    extends OneSequenceGestureRecognizer {
  _BypassPlatformViewGestureRecognizer(
    this.controller,
    this.gestureRecognizerFactories, {
    Set<PointerDeviceKind>? supportedDevices,
  }) : super(supportedDevices: supportedDevices) {
    team = GestureArenaTeam()..captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
      (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        final OneSequenceGestureRecognizer gestureRecognizer =
            recognizerFactory.constructor();
        gestureRecognizer.team = team;
        // The below gesture recognizers requires at least one non-empty callback to
        // compete in the gesture arena.
        // https://github.com/flutter/flutter/issues/35394#issuecomment-562285087
        if (gestureRecognizer is LongPressGestureRecognizer) {
          gestureRecognizer.onLongPress ??= () {};
        } else if (gestureRecognizer is DragGestureRecognizer) {
          gestureRecognizer.onDown ??= (_) {};
        } else if (gestureRecognizer is TapGestureRecognizer) {
          gestureRecognizer.onTapDown ??= (_) {};
        }
        return gestureRecognizer;
      },
    ).toSet();
  }

  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  //  get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  late Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  final GestureRecognitionPlatformViewController controller;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    for (final OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
        debugPrint("Accept gesture.");
    controller.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    debugPrint("Reject gesture.");
    controller.rejectGesture();
  }

  void reset() {
    resolve(GestureDisposition.rejected);
  }
}

// This recognizer constructs gesture recognizers from a set of gesture recognizer factories
// it was given, adds all of them to a gesture arena team with the _GtkViewGestureRecognizer
// as the team captain.
// When the team wins a gesture the recognizer notifies the engine that it should release
// the touch sequence to the embedded GtkWidget.
class _GtkViewGestureRecognizer extends _BypassPlatformViewGestureRecognizer {
  _GtkViewGestureRecognizer(
    GtkViewController controller,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories, {
    Set<PointerDeviceKind>? supportedDevices,
  }) : super(controller, gestureRecognizerFactories,
            supportedDevices: supportedDevices);

  @override
  String get debugDescription => 'GtkWidget view';
}

/// A render object for a Linux GtkWidget.
///
/// {@template flutter.rendering.RenderGtkView}
/// Embedding GtkWidgets is still preview-quality.
/// {@endtemplate}
///
/// [RenderGtkView] is responsible for sizing and displaying a Linux GtkWidget.
///
/// GtkWidgets are added as subwidgets of the FlutterView and are composited by Gtk.
///
/// {@macro flutter.rendering.RenderAndroidView.layout}
///
/// {@macro flutter.rendering.RenderAndroidView.gestures}
///
/// See also:
///
///  * [GtkView] which is a widget that is used to show a GtkWidget.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderGtkView
    extends _RenderGestureRecognitionPlatformView<GtkViewController> {
  /// Creates a render object for a Linux GtkWidget.
  ///
  /// The `viewId`, `hitTestBehavior`, and `gestureRecognizers` parameters must not be null.
  RenderGtkView({
    required GtkViewController viewController,
    required PlatformViewHitTestBehavior hitTestBehavior,
    required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : super(
            viewController: viewController,
            hitTestBehavior: hitTestBehavior,
            gestureRecognizers: gestureRecognizers);

  @override
  _GtkViewGestureRecognizer _createGestureRecognizer(
      GtkViewController viewController,
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    return _GtkViewGestureRecognizer(viewController, gestureRecognizers);
  }
}

class PlatformViewServices {
  /// Creates a controller for a new Linux GtkWidget.
  ///
  /// `id` is an unique identifier generated with [platformViewsRegistry].
  ///
  /// `viewType` is the identifier of the GtkWidget type to be created, a
  /// factory for this view type must have been registered on the platform side.
  /// Platform view factories are typically registered by plugin code.
  ///
  /// The `id` and `viewType` parameters must not be null.
  /// If `creationParams` is non null then `creationParamsCodec` must not be null.
  static Future<GtkViewController> initGtkView({
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
  }) async {
    assert(creationParams == null || creationParamsCodec != null);

    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': viewType,
      'direction': GtkViewController._getGtkTextDirection(layoutDirection),
    };

    if (creationParams != null) {
      final ByteData paramsByteData =
          creationParamsCodec!.encodeMessage(creationParams)!;
      args['params'] = Uint8List.view(
          paramsByteData.buffer, 0, paramsByteData.lengthInBytes);
    }

    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    return GtkViewController._(id, layoutDirection);
  }
}

/// Embeds a Linux GtkWidget in the Widget hierarchy.
///
/// {@macro flutter.rendering.RenderGtkView}
///
/// Embedding Linux GtkWidget is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// {@macro flutter.widgets.AndroidView.layout}
///
/// {@macro flutter.widgets.AndroidView.gestures}
///
/// {@macro flutter.widgets.AndroidView.lifetime}
///
/// Construction of GtkWidget is done asynchronously, before the GtkWidget is ready this widget paints
/// nothing while maintaining the same layout constraints.
class GtkView extends StatefulWidget {
  /// Creates a widget that embeds an GtkWidget.
  ///
  /// {@macro flutter.widgets.AndroidView.constructorArgs}
  const GtkView({
    Key? key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.gestureRecognizers,
    this.layoutDirection,
    this.creationParams,
    this.creationParamsCodec,
  })  : assert(creationParams == null || creationParamsCodec != null),
        super(key: key);

  /// The unique identifier for Linux GtkWidget view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// {@macro flutter.widgets.AndroidView.onPlatformViewCreated}
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  /// {@macro flutter.widgets.AndroidView.hitTestBehavior}
  final PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.widgets.AndroidView.layoutDirection}
  final TextDirection? layoutDirection;

  /// Passed as the `arguments` argument of [-\[FlPlatformViewFactory::create_platform_view\]](/not_existing_yet.html)
  ///
  /// This can be used by plugins to pass constructor parameters to the embedded iOS view.
  final dynamic creationParams;

  /// The codec used to encode `creationParams` before sending it to the
  /// platform side. It should match the codec returned by [-\[FlPlatformViewFactory::get_create_arguments_codec\]](/not_existing_yet.html)
  ///
  /// This is typically one of: [StandardMessageCodec], [JSONMessageCodec], [StringCodec], or [BinaryCodec].
  ///
  /// This must not be null if [creationParams] is not null.
  final MessageCodec<dynamic>? creationParamsCodec;

  /// Which gestures should be forwarded to the Linux GtkWidget view.
  ///
  /// {@macro flutter.widgets.AndroidView.gestureRecognizers.descHead}
  ///
  /// For example, with the following setup vertical drags will not be dispatched to the UIKit
  /// view as the vertical drag gesture is claimed by the parent [GestureDetector].
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: GtkView(
  ///     viewType: 'webview',
  ///   ),
  /// )
  /// ```
  ///
  /// To get the [GtkView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: GtkView(
  ///       viewType: 'webview',
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
  ///         new Factory<OneSequenceGestureRecognizer>(
  ///           () => new EagerGestureRecognizer(),
  ///         ),
  ///       ].toSet(),
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// {@macro flutter.widgets.AndroidView.gestureRecognizers.descFoot}
  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<GtkView> createState() => _GtkViewState();
}

class _GtkViewState extends State<GtkView> {
  GtkViewController? _controller;
  TextDirection? _layoutDirection;
  bool _initialized = false;

  late bool _mouseIsConnected;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  void initState() {
    super.initState();

    _mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;

    // Listen to see when a mouse is added.
    RendererBinding.instance.mouseTracker
        .addListener(_handleMouseTrackerChange);
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected =
        RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      setState(() {
        _mouseIsConnected = mouseIsConnected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.expand();
    }
    Widget result = _GtkPlatformView(
      controller: _controller!,
      hitTestBehavior: widget.hitTestBehavior,
      gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
    );

    if (_mouseIsConnected) {
      result = MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: result,
      );
    }

    return result;
  }

  void _onEnter(PointerEnterEvent event) {
    _controller?.enter();
  }

  void _onExit(PointerExitEvent event) {
    _controller?.exit();
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewGtkView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      _controller?.setLayoutDirection(_layoutDirection!);
    }
  }

  @override
  void didUpdateWidget(GtkView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller?.dispose();
      _createNewGtkView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(_layoutDirection!);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    RendererBinding.instance.mouseTracker
        .removeListener(_handleMouseTrackerChange);
    super.dispose();
  }

  Future<void> _createNewGtkView() async {
    final int id = platformViewsRegistry.getNextPlatformViewId();
    final GtkViewController controller = await PlatformViewServices.initGtkView(
      id: id,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection!,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    if (widget.onPlatformViewCreated != null) {
      widget.onPlatformViewCreated!(id);
    }
    setState(() {
      _controller = controller;
    });
  }
}

class _GtkPlatformView extends LeafRenderObjectWidget {
  const _GtkPlatformView({
    Key? key,
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
  }) : super(key: key);

  final GtkViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGtkView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGtkView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}