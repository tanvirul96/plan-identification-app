import 'package:flutter/material.dart';
import 'services/rag_service.dart';
import 'screens/identify_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/explorer_screen.dart';

void main() {
  runApp(const PlantIdentificationApp());
}

class PlantIdentificationApp extends StatelessWidget {
  const PlantIdentificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2E7D32);

    return MaterialApp(
      title: 'Medicinal Plant ID & RAG Assistant',
      debugShowCheckedModeBanner: false,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
          primary: seedColor,
          surface: const Color(0xFFF4F9F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F9F5),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF0E1711),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1711),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF16241A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),

      themeMode: ThemeMode.system,
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  final RagService _ragService = RagService();
  String? _activePlantContext;

  void _onPlantIdentified(String plantName) {
    setState(() {
      _activePlantContext = plantName;
    });
  }

  void _onSelectPlantForChat(String plantName) {
    setState(() {
      _activePlantContext = plantName;
      _currentIndex = 1; // Switch to Chat tab
    });
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      IdentifyScreen(
        ragService: _ragService,
        onPlantIdentified: _onPlantIdentified,
      ),
      ChatScreen(
        ragService: _ragService,
        activePlant: _activePlantContext,
      ),
      ExplorerScreen(
        ragService: _ragService,
        onSelectPlantForChat: _onSelectPlantForChat,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🌿 Medicinal Plant RAG"),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: "Identify",
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: "RAG Chat",
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: "Explorer",
          ),
        ],
      ),
    );
  }
}
