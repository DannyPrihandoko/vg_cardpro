import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'deck_list_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final CupertinoTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CupertinoTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF111827),
        activeColor: const Color(0xFF60A5FA),
        inactiveColor: const Color(0xFF6B7280),
        border: const Border(
          top: BorderSide(color: Color(0xFF1F2937), width: 0.8),
        ),
        height: 58,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.search, size: 24),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.search, size: 24),
            ),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.layers_alt, size: 24),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.layers_alt_fill, size: 24),
            ),
            label: 'My Decks',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomeScreen();
          case 1:
            return const DeckListScreen();
          default:
            return const HomeScreen();
        }
      },
    );
  }
}
