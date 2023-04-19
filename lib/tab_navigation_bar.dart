library tab_navigation_bar;

import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kIndicatorHeight = 32;
const double _kIndicatorWidth = 64;

class TabNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  const TabNavigationBar({
    super.key,
    required this.tabs,
    this.controller,
    this.padding  = const EdgeInsets.all(8.0),
    // this.indicatorColor,
    // this.labelColor,
    // this.labelStyle,
    // this.mouseCursor,
    // this.enableFeedback,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.onTap,
  });

  final List<Widget> tabs;

  final TabController? controller;

  final EdgeInsetsGeometry padding;

  // final MaterialStateProperty<Color?>? indicatorColor;

  // final MaterialStateProperty<Color?>? labelColor;

  // final MaterialStateProperty<TextStyle?>? labelStyle;

  // final MouseCursor? mouseCursor;

  // final bool? enableFeedback;

  final ScrollNotificationPredicate notificationPredicate;


  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize {
    double maxHeight = TabNavigationBarDefaults.tabHeight;
    for (final Widget item in tabs) {
      if (item is PreferredSizeWidget) {
        final double itemHeight = item.preferredSize.height;
        maxHeight = math.max(itemHeight, maxHeight);
      }
    }
    return Size.fromHeight(maxHeight + padding.vertical);
  }


  @override
  State<TabNavigationBar> createState() => _TabNavigationBarState();
}

class _TabNavigationBarState extends State<TabNavigationBar> with SingleTickerProviderStateMixin {
  TabController? _controller;
  int? _currentIndex;
  ScrollNotificationObserverState? _scrollNotificationObserver;
  bool _scrolledUnder = false;

  void _updateTabController() {
    final TabController? newController = widget.controller ?? DefaultTabController.maybeOf(context);
    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.',
        );
      }
      return true;
    }());

    if (newController == _controller) {
      return;
    }

    _controller = newController;
    if (_controller != null) {
      _controller!.addListener(_handleTabControllerTick);
      _currentIndex = _controller!.index;
    }
  }

  void _handleTabControllerTick() {
    if (_controller!.index != _currentIndex) {
      _currentIndex = _controller!.index;
    }
    setState(() {
      // Rebuild the tabs after a (potentially animated) index change
      // has completed.
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
    _currentIndex = _controller!.index;
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void didUpdateWidget(TabNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController();
      _currentIndex = _controller!.index;
    }
  }

  @override
  void dispose() {
    if (_scrollNotificationObserver != null) {
      _scrollNotificationObserver!.removeListener(_handleScrollNotification);
      _scrollNotificationObserver = null;
    }
    _controller = null;
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && widget.notificationPredicate(notification)) {
      final bool oldScrolledUnder = _scrolledUnder;
      final ScrollMetrics metrics = notification.metrics;
      switch (metrics.axisDirection) {
        case AxisDirection.up:
          // Scroll view is reversed
          _scrolledUnder = metrics.extentAfter > 0;
          break;
        case AxisDirection.down:
          _scrolledUnder = metrics.extentBefore > 0;
          break;
        case AxisDirection.right:
        case AxisDirection.left:
          // Scrolled under is only supported in the vertical axis, and should
          // not be altered based on horizontal notifications of the same
          // predicate since it could be a 2D scroller.
          break;
      }

      if (_scrolledUnder != oldScrolledUnder) {
        setState(() {
          // React to a change in MaterialState.scrolledUnder
        });
      }
    }
  }


  void _handleTap(int index) {
    assert(index >= 0 && index < widget.tabs.length);
    _controller!.animateTo(index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TabNavigationBarDefaults defaults = TabNavigationBarDefaults(context);

    final List<Widget> wrappedTabs = List<Widget>.generate(widget.tabs.length, (int index) {
      final PreferredSizeWidget tab = widget.tabs[index] as PreferredSizeWidget;

      return SizedBox(
        height: tab.preferredSize.height,
        child: Center(
          heightFactor: 1.0,
          child: widget.tabs[index],
        ),
      );
    });

    final int tabCount = widget.tabs.length;
    for (int index = 0; index < tabCount; index += 1) {
      final Set<MaterialState> selectedState = <MaterialState>{
        if (index == _currentIndex) MaterialState.selected,
      };

      // wrappedTabs[index] = wrappedTabs[index];
      // wrappedTabs[index] = InkWell(
      //   onTap: () { _handleTap(index); },
      //   customBorder: defaults.indicatorShape,
      //   child: Ink(
      //     decoration: ShapeDecoration(
      //       shape: defaults.indicatorShape,
      //       color: defaults.indicatorColor!.resolve(selectedState),
      //     ),
      //     child: wrappedTabs[index],
      //   ),
      // );
    }

    final FlexibleSpaceBarSettings? settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final Set<MaterialState> states = <MaterialState>{
      if (settings?.isScrolledUnder ?? _scrolledUnder) MaterialState.scrolledUnder,
    };
    final double effectiveElevation = states.contains(MaterialState.scrolledUnder)
      ? 3.0
      : defaults.elevation;

    final Color effectiveShadowColor = states.contains(MaterialState.scrolledUnder)
      ? colorScheme.shadow
      : defaults.shadowColor!;

    final EdgeInsetsGeometry effectiveBottomPadding = states.contains(MaterialState.scrolledUnder)
      ? widget.padding.add(EdgeInsets.symmetric(horizontal: widget.padding.horizontal * 15))
      : widget.padding;

    return AnimatedPadding(
      padding: effectiveBottomPadding,
      curve: Curves.fastEaseInToSlowEaseOut,
      duration: const Duration(milliseconds: 300),
      child: Material(
        elevation: effectiveElevation,
        surfaceTintColor: defaults.surfaceTintColor,
        shadowColor: effectiveShadowColor,
        color: defaults.backgroundColor,
        shape: defaults.indicatorShape,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < tabCount; i += 1)
              Flexible(
                child: _SelectableAnimatedBuilder(
                  duration: const Duration(milliseconds: 500),
                  isSelected: i == _controller?.index,
                  builder: (BuildContext context, Animation<double> animation) {
                    return _TabDestinationInfo(
                      selectedAnimation: animation,
                      onTap: () {
                        _handleTap(i);
                      },
                      child: wrappedTabs[i],
                    );
                  }
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TabDestination extends StatelessWidget implements PreferredSizeWidget {
  const TabDestination({
    super.key,
    required this.icon,
    required this.label,
    this.height,
  });

  final IconData icon;
  final String label;
  final double? height;

  @override
  Size get preferredSize => Size.fromHeight(height ?? TabNavigationBarDefaults.tabHeight);

  @override
  Widget build(BuildContext context) {
    final _TabDestinationInfo info = _TabDestinationInfo.of(context);
    final TabNavigationBarDefaults defaults = TabNavigationBarDefaults(context);
    const Set<MaterialState> selectedState = <MaterialState>{MaterialState.selected};
    const Set<MaterialState> unselectedState = <MaterialState>{};
    final Animation<double> animation = info.selectedAnimation;

    return InkWell(
      customBorder: defaults.indicatorShape,
      onTap: info.onTap,
      splashFactory: InkRipple.splashFactory,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          NavigationIndicator(
            animation: animation,
            width: double.infinity,
            height: double.infinity,
            color: defaults.indicatorColor!.resolve(selectedState),
            shape: defaults.indicatorShape
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isForwardOrCompleted(Animation<double> animation) {
  return animation.status == AnimationStatus.forward
      || animation.status == AnimationStatus.completed;
}

class NavigationIndicator extends StatelessWidget {
  /// Builds an indicator, usually used in a stack behind the icon of a
  /// navigation bar destination.
  const NavigationIndicator({
    super.key,
    required this.animation,
    this.color,
    this.width = _kIndicatorWidth,
    this.height = _kIndicatorHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.shape,
  });

  /// Determines the scale of the indicator.
  ///
  /// When [animation] is 0, the indicator is not present. The indicator scales
  /// in as [animation] grows from 0 to 1.
  final Animation<double> animation;

  /// The fill color of this indicator.
  ///
  /// If null, defaults to [ColorScheme.secondary].
  final Color? color;

  /// The width of this indicator.
  ///
  /// Defaults to `64`.
  final double width;

  /// The height of this indicator.
  ///
  /// Defaults to `32`.
  final double height;

  /// The border radius of the shape of the indicator.
  ///
  /// This is used to create a [RoundedRectangleBorder] shape for the indicator.
  /// This is ignored if [shape] is non-null.
  ///
  /// Defaults to `BorderRadius.circular(16)`.
  final BorderRadius borderRadius;

  /// The shape of the indicator.
  ///
  /// If non-null this is used as the shape used to draw the background
  /// of the indicator. If null then a [RoundedRectangleBorder] with the
  /// [borderRadius] is used.
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        // The scale should be 0 when the animation is unselected, as soon as
        // the animation starts, the scale jumps to 40%, and then animates to
        // 100% along a curve.
        final double scale = animation.isDismissed
            ? 0.0
            : Tween<double>(begin: .4, end: 1.0).transform(
            CurveTween(curve: Curves.easeInOutCubicEmphasized).transform(animation.value));

        return Transform(
          alignment: Alignment.center,
          // Scale in the X direction only.
          transform: Matrix4.diagonal3Values(
            scale,
            1.0,
            1.0,
          ),
          child: child,
        );
      },
      // Fade should be a 100ms animation whenever the parent animation changes
      // direction.
      child: _StatusTransitionWidgetBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return _SelectableAnimatedBuilder(
            isSelected: _isForwardOrCompleted(animation),
            duration: const Duration(milliseconds: 100),
            alwaysDoFullAnimation: true,
            builder: (BuildContext context, Animation<double> fadeAnimation) {
              return FadeTransition(
                opacity: fadeAnimation,
                child: Ink(
                  width: width,
                  height: height,
                  decoration: ShapeDecoration(
                    shape: shape ?? RoundedRectangleBorder(borderRadius: borderRadius),
                    color: color ?? Theme.of(context).colorScheme.secondary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusTransitionWidgetBuilder extends StatusTransitionWidget {
  /// Creates a widget that rebuilds when the given animation changes status.
  const _StatusTransitionWidgetBuilder({
    required super.animation,
    required this.builder,
    this.child,
  });

  /// Called every time the [animation] changes [AnimationStatus].
  final TransitionBuilder builder;

  /// The child widget to pass to the [builder].
  ///
  /// If a [builder] callback's return value contains a subtree that does not
  /// depend on the animation, it's more efficient to build that subtree once
  /// instead of rebuilding it on every animation status change.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance in some cases and is therefore a good practice.
  ///
  /// See: [AnimatedBuilder.child]
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

class _TabDestinationInfo extends InheritedWidget {
  const _TabDestinationInfo({
    required this.selectedAnimation,
    required this.onTap,
    required super.child,
  });

  final Animation<double> selectedAnimation;
  final VoidCallback onTap;


  static _TabDestinationInfo of(BuildContext context) {
    final _TabDestinationInfo? result = context.dependOnInheritedWidgetOfExactType<_TabDestinationInfo>();
    assert(
      result != null,
      'Tab destinations need a _TabDestinationInfo parent, '
      'which is usually provided by TabNavigationBar.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(_TabDestinationInfo oldWidget) {
    return selectedAnimation != oldWidget.selectedAnimation;
  }
}

class _SelectableAnimatedBuilder extends StatefulWidget {
  /// Builds and maintains an [AnimationController] that will animate from 0 to
  /// 1 and back depending on when [isSelected] is true.
  const _SelectableAnimatedBuilder({
    required this.isSelected,
    this.duration = const Duration(milliseconds: 200),
    this.alwaysDoFullAnimation = false,
    required this.builder,
  });

  /// When true, the widget will animate an animation controller from 0 to 1.
  ///
  /// The animation controller is passed to the child widget through [builder].
  final bool isSelected;

  /// How long the animation controller should animate for when [isSelected] is
  /// updated.
  ///
  /// If the animation is currently running and [isSelected] is updated, only
  /// the [duration] left to finish the animation will be run.
  final Duration duration;

  /// If true, the animation will always go all the way from 0 to 1 when
  /// [isSelected] is true, and from 1 to 0 when [isSelected] is false, even
  /// when the status changes mid animation.
  ///
  /// If this is false and the status changes mid animation, the animation will
  /// reverse direction from it's current point.
  ///
  /// Defaults to false.
  final bool alwaysDoFullAnimation;

  /// Builds the child widget based on the current animation status.
  ///
  /// When [isSelected] is updated to true, this builder will be called and the
  /// animation will animate up to 1. When [isSelected] is updated to
  /// `false`, this will be called and the animation will animate down to 0.
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  _SelectableAnimatedBuilderState createState() =>
      _SelectableAnimatedBuilderState();
}

/// State that manages the [AnimationController] that is passed to
/// [_SelectableAnimatedBuilder.builder].
class _SelectableAnimatedBuilderState extends State<_SelectableAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.duration = widget.duration;
    _controller.value = widget.isSelected ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(_SelectableAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: widget.alwaysDoFullAnimation ? 0 : null);
      } else {
        _controller.reverse(from: widget.alwaysDoFullAnimation ? 1 : null);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _controller,
    );
  }
}


mixin TabNavigationBarConfig {
  double get elevation;
  Color? get surfaceTintColor;
  Color? get backgroundColor;
  Color? get shadowColor;
  MaterialStateProperty<Color?>? get indicatorColor;
  ShapeBorder get indicatorShape;
}

class TabNavigationBarDefaults with TabNavigationBarConfig {
  TabNavigationBarDefaults(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  static double tabHeight = 79.0;

  @override
  double get elevation => 1.0;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  MaterialStateProperty<Color?>? get indicatorColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.secondaryContainer;
      }
      return null;
    });
  }

  @override
  ShapeBorder get indicatorShape => const StadiumBorder();
}
