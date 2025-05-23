import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttergram/controllers/bottom_nav_controller.dart';
import 'package:fluttergram/screens/home/home_screen.dart';
import 'package:fluttergram/screens/search/search_screen.dart';
import 'package:fluttergram/screens/notifications/notifications_screen.dart';
import 'package:fluttergram/screens/profile/profile_screen.dart';
import 'package:fluttergram/screens/messages/messages_screen.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../screens/create_post/media_selection_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  final List<Widget> screens = const [
    HomeScreen(),
    SearchScreen(),
    SizedBox.shrink(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(BottomNavController());

    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text(
          'Fluttergram',
          style: GoogleFonts.pacifico(
              fontSize: 26,
              color: Colors.white,
              letterSpacing: 1.5
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.facebookMessenger),
            onPressed: () {
              Get.to(() =>  MessagesScreen());
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: navController.currentIndex.value == 2 ? Container() : screens[navController.currentIndex.value],
      ),
      bottomNavigationBar: StylishBottomBar(
        currentIndex: navController.currentIndex.value,
        onTap: (index) {
          if (index == 2) {
            Get.to(() => const MediaSelectionScreen());
          } else {
            navController.changeTab(index);
          }
        },
        backgroundColor: Colors.black,
        option: AnimatedBarOptions(
          iconSize: 32,
          barAnimation: BarAnimation.fade,
          iconStyle: IconStyle.animated,
          opacity: 0.3,
        ),
        items: [
          BottomBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            selectedIcon: Icon(Icons.home_filled, color: Colors.red[400]),
            title: Text(''),
          ),
          BottomBarItem(
            icon: Icon(Icons.search, color: Colors.grey),
            selectedIcon: Icon(Icons.search, color: Colors.red[400]),
            title: Text(''),
          ),
          BottomBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
            title: const Text(''),
          ),
          BottomBarItem(
            icon: Icon(Icons.favorite_border, color: Colors.grey),
            selectedIcon: Icon(Icons.favorite, color: Colors.red[400]),
            title: Text(''),
          ),
          BottomBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Colors.red[400]),
            title: Text(''),
          ),
        ],
      ),
    ));
  }
}