import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/screens/auth/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttergram/screens/create_post/create_post.dart';
import 'package:fluttergram/screens/home/home_screen.dart';
import 'package:fluttergram/screens/messages/messages_screen.dart';
import 'package:fluttergram/screens/notifications/notifications_screen.dart';
import 'package:fluttergram/screens/profile/profile_screen.dart';
import 'package:fluttergram/screens/search/search_screen.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/bottom_nav_controller.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://phucklrkdeheqxxrjxxr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBodWNrbHJrZGVoZXF4eHJqeHhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NjEyMzgsImV4cCI6MjA2MDQzNzIzOH0.UOhPNnBTlIAZBMLYEy_NQFadNAujK7_iIxdDrOGEg2s',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      // theme: ThemeData(
      //   primarySwatch: Colors.pink,
      //   colorScheme: ColorScheme(
      //     brightness: Brightness.light,
      //     primary: Color(0xFFE1306C),
      //     onPrimary: Colors.white,
      //     secondary: Color(0xFFFFC107),
      //     onSecondary: Colors.black,
      //     error: Colors.red,
      //     onError: Colors.white,
      //     surface: Colors.white,
      //     onSurface: Colors.black,
      //   ),
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      // ),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE1306C),
          onPrimary: Colors.white,
          secondary: Color(0xFFFFC107),
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

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
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: navController.currentIndex.value == 2 ? Container() : screens[navController.currentIndex.value],
      ),
      bottomNavigationBar: StylishBottomBar(
        currentIndex: navController.currentIndex.value,
        onTap: (index) {
          if (index == 2) {
            Get.to(() => const CreatePostScreen());
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
            selectedIcon: Icon(Icons.home_filled, color: Colors.pinkAccent),
            title: Text(''),
          ),
          BottomBarItem(
            icon: Icon(Icons.search, color: Colors.grey),
            selectedIcon: Icon(Icons.search, color: Colors.pinkAccent),
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
            selectedIcon: Icon(Icons.favorite, color: Colors.pinkAccent),
            title: Text(''),
          ),
          BottomBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Colors.pinkAccent),
            title: Text(''),
          ),
        ],
      ),
    ));
  }
}