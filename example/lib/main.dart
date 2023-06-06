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
      home: const Example(),
    );
  }
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sample'),
          scrolledUnderElevation: 0.0,
          bottom: TabNavigationBar(
            notificationPredicate: (ScrollNotification notification) {
              if (notification.depth == 0 ||
                  notification.depth == 1 ||
                  notification.depth == 2) {
                return true;
              }
              return false;
            },
            tabs: const <Widget>[
              TabDestination(
                icon: Icon(Icons.info),
                label: 'Info',
              ),
              TabDestination(
                icon: Icon(Icons.info),
                label: 'Info',
              ),
              TabDestination(
                icon: Icon(Icons.info),
                label: 'Info',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
            ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
            ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
