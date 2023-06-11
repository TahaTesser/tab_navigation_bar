import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TabNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  const TabNavigationBar({
    super.key,
    required this.tabs,
    this.controller,
    this.padding = const EdgeInsets.all(8.0),
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.indicatorColor,
  }) : assert(tabs.length <= 3);

  final List<Widget> tabs;

  final TabController? controller;

  final EdgeInsets padding;

  final ScrollNotificationPredicate notificationPredicate;

  final ValueChanged<int>? onTap;

  final Color? backgroundColor;

  final MaterialStateProperty<double?>?  elevation;

  final MaterialStateProperty<Color?>?  shadowColor;

  final Color? surfaceTintColor;

  final ShapeBorder? shape;

  final MaterialStateProperty<Color?>? indicatorColor;

  @override
  Size get preferredSize {
    double maxHeight = _TabNavigationBarDefaults.tabHeight;
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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

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
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      final double tabSize = maxScrollExtent / widget.tabs.length;
      final double tabPosition = tabSize * (_currentIndex! + 1);
      _scrollController.animateTo(
        _currentIndex == 0 ? 0 : tabPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() {
      // Rebuild the tabs after a (potentially animated) index change
      // has completed.
    });
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && widget.notificationPredicate(notification)) {
      final bool oldScrolledUnder = _scrolledUnder;
      final ScrollMetrics metrics = notification.metrics;
      switch (metrics.axisDirection) {
        case AxisDirection.up:
          // Scroll view is reversed
          _scrolledUnder = metrics.extentAfter > 0;
        case AxisDirection.down:
          _scrolledUnder = metrics.extentBefore > 0;
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
    _scrollController.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _TabNavigationBarDefaults defaults = _TabNavigationBarDefaults(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);

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

    void handleTap(int index) {
      assert(index >= 0 && index < widget.tabs.length);
      setState(() {
        _scrolledUnder = false;
      });
      _controller!.animateTo(index);
      widget.onTap?.call(index);
    }

    final FlexibleSpaceBarSettings? settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final Set<MaterialState> states = <MaterialState>{
      if (settings?.isScrolledUnder ?? _scrolledUnder)
        MaterialState.scrolledUnder,
    };

    EdgeInsetsGeometry effectiveBottomPadding = widget.padding;
    if (states.contains(MaterialState.scrolledUnder) && mediaQuery.size.width > 600) {
      effectiveBottomPadding = effectiveBottomPadding.add(EdgeInsets.symmetric(horizontal: widget.padding.horizontal * 4));
    }

    return AnimatedPadding(
      padding: effectiveBottomPadding,
      curve: Curves.fastEaseInToSlowEaseOut,
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: widget.backgroundColor ?? defaults.backgroundColor,
        elevation: widget.elevation?.resolve(states) ?? defaults.elevation!.resolve(states)!,
        shadowColor: widget.shadowColor?.resolve(states) ?? defaults.shadowColor!.resolve(states)!,
        surfaceTintColor: widget.surfaceTintColor ?? defaults.surfaceTintColor,
        shape: widget.shape ?? defaults.shape,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: widget.preferredSize.height - effectiveBottomPadding.vertical,
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            }),
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.tabs.length,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemBuilder:(BuildContext context, int index) {
                  return _SelectableAnimatedBuilder(
                    duration: const Duration(milliseconds: 500),
                    isSelected: index == _currentIndex,
                    builder: (BuildContext context, Animation<double> animation) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (mediaQuery.size.width - effectiveBottomPadding.horizontal) / 3,
                        ),
                        child: _TabDestinationInfo(
                          selectedIndex: _currentIndex ?? 0,
                          selectedAnimation: animation,
                          onTap: () => handleTap(index),
                          child: wrappedTabs[index],
                        ),
                      );
                    }
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TabDestination extends StatelessWidget implements PreferredSizeWidget {
  const TabDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;


  @override
  Size get preferredSize => Size.fromHeight(_TabNavigationBarDefaults.tabHeight);

  @override
  Widget build(BuildContext context) {
    final _TabDestinationInfo info = _TabDestinationInfo.of(context);
    final _TabNavigationBarDefaults defaults = _TabNavigationBarDefaults(context);
    const Set<MaterialState> selectedState = <MaterialState>{MaterialState.selected};
    final Animation<double> animation = info.selectedAnimation;

    return InkWell(
      customBorder: defaults.shape,
      splashFactory: InkRipple.splashFactory,
      onTap: info.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          NavigationIndicator(
            animation: animation,
            width: double.infinity,
            height: double.infinity,
            color: defaults.indicatorColor!.resolve(selectedState),
            shape: defaults.shape
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabDestinationInfo extends InheritedWidget {
  const _TabDestinationInfo({
    required this.selectedIndex,
    required this.selectedAnimation,
    required this.onTap,
    required super.child,
  });

  final int selectedIndex;
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
    // ignore: unused_element
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

mixin _TabNavigationBarConfig {
  Color? get backgroundColor;
  MaterialStateProperty<double?>? get elevation;
  MaterialStateProperty<Color?>? get shadowColor;
  Color? get surfaceTintColor;
  ShapeBorder get shape;
  MaterialStateProperty<Color?>? get indicatorColor;
}

class _TabNavigationBarDefaults with _TabNavigationBarConfig {
  _TabNavigationBarDefaults(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<double?>? get elevation {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.scrolledUnder)) {
        return 3.0;
      }
      return 1.0;
    });
  }

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  MaterialStateProperty<Color?>? get shadowColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.scrolledUnder)) {
        return _colors.shadow;
      }
      return Colors.transparent;
    });
  }

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  ShapeBorder get shape => const StadiumBorder();

  @override
  MaterialStateProperty<Color?>? get indicatorColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return _colors.secondaryContainer;
      }
      return null;
    });
  }

  static double get tabHeight => 79.0;
}
