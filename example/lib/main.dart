import 'package:flutter/material.dart';
import 'package:tab_navigation_bar/tab_navigation_bar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const TabNavigationBarExample(),
    );
  }
}

class TabNavigationBarExample extends StatefulWidget {
  const TabNavigationBarExample({super.key});

  @override
  State<TabNavigationBarExample> createState() =>
      _TabNavigationBarExampleState();
}

class _TabNavigationBarExampleState extends State<TabNavigationBarExample>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    )..addListener(() {
         _scrollController.jumpTo(
                (_scrollController.position.maxScrollExtent / 2.0) *
                    _animation.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Card(
                        child: SizedBox(
                            height: 350,
                            child: Center(
                              child: Text(
                                'TabNavigationBar',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge!
                                    .copyWith(
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ))),
                  ),
                  const Expanded(
                    child: Card(
                        child: SizedBox(
                      height: 350,
                      child: FlutterLogo(),
                    )),
                  ),
                ],
              ),
            ),
            const SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              toolbarHeight: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              bottom: TabNavigationBar(
                tabs: <Widget>[
                  TabDestination(
                    icon: Icons.info,
                    label: 'Overview',
                  ),
                  TabDestination(
                    icon: Icons.style_outlined,
                    label: 'Specs',
                  ),
                  TabDestination(
                    icon: Icons.design_services_outlined,
                    label: 'Guidelines',
                  ),
                  TabDestination(
                    icon: Icons.accessibility,
                    label: 'Accessibility',
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 290),
              sliver: SliverList.builder(
                itemCount: 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:tab_navigation_bar/tab_navigation_bar.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(useMaterial3: true),
//       home: const TabNavigationBarExample(),
//     );
//   }
// }

// class TabNavigationBarExample extends StatelessWidget {
//   const TabNavigationBarExample({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('TabNavigationBar'),
//           bottom: const TabNavigationBar(
//             tabs: <Widget>[
//               TabDestination(
//                 icon: Icons.info,
//                 label: 'Overview',
//               ),
//               TabDestination(
//                 icon: Icons.style_outlined,
//                 label: 'Specs',
//               ),
//               TabDestination(
//                 icon: Icons.design_services_outlined,
//                 label: 'Guidelines',
//               ),
//               TabDestination(
//                 icon: Icons.accessibility,
//                 label: 'Accessibility',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
