import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/rag_service.dart';
import 'screens/identify_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/explorer_screen.dart';
import 'widgets/neu_widgets.dart';

void main() {
  runApp(const PlantIdentificationApp());
}

class PlantIdentificationApp extends StatelessWidget {
  const PlantIdentificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicinal Plant ID & RAG Assistant',
      debugShowCheckedModeBanner: false,

      // ── Neumorphism Light Theme ──
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NeuTheme.lightPrimary,
          brightness: Brightness.light,
          primary: NeuTheme.lightPrimary,
          surface: NeuTheme.lightBg,
          onSurface: NeuTheme.lightOnSurface,
        ),
        scaffoldBackgroundColor: NeuTheme.lightBg,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: NeuTheme.lightBg,
          foregroundColor: NeuTheme.lightOnSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            color: NeuTheme.lightOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: NeuTheme.lightBg,
          selectedIconTheme: const IconThemeData(color: NeuTheme.lightPrimary),
          unselectedIconTheme: IconThemeData(color: NeuTheme.lightOnSurface.withValues(alpha: 0.5)),
          selectedLabelTextStyle: const TextStyle(
            color: NeuTheme.lightPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: NeuTheme.lightOnSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: NeuTheme.lightBg,
          indicatorColor: NeuTheme.lightPrimary.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: NeuTheme.lightPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: NeuTheme.lightOnSurface.withValues(alpha: 0.5),
              fontSize: 12,
            );
          }),
        ),
      ),

      // ── Neumorphism Dark Theme ──
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NeuTheme.darkPrimary,
          brightness: Brightness.dark,
          primary: NeuTheme.darkPrimary,
          surface: NeuTheme.darkBg,
          onSurface: NeuTheme.darkOnSurface,
        ),
        scaffoldBackgroundColor: NeuTheme.darkBg,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: NeuTheme.darkBg,
          foregroundColor: NeuTheme.darkOnSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            color: NeuTheme.darkOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: NeuTheme.darkBg,
          selectedIconTheme: const IconThemeData(color: NeuTheme.darkPrimary),
          unselectedIconTheme: IconThemeData(color: NeuTheme.darkOnSurface.withValues(alpha: 0.4)),
          selectedLabelTextStyle: const TextStyle(
            color: NeuTheme.darkPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: NeuTheme.darkOnSurface.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: NeuTheme.darkBg,
          indicatorColor: NeuTheme.darkPrimary.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: NeuTheme.darkPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return TextStyle(
              color: NeuTheme.darkOnSurface.withValues(alpha: 0.4),
              fontSize: 12,
            );
          }),
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
      _currentIndex = 1;
    });
  }

  Future<bool> _onWillPop() async {
    // Only show exit dialog on mobile platforms
    if (kIsWeb) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: NeuTheme.primaryColor(context)),
            const SizedBox(width: 12),
            const Text('Exit App'),
          ],
        ),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Stay',
              style: TextStyle(
                color: NeuTheme.primaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    final screens = [
      IdentifyScreen(
        key: const PageStorageKey('identify_screen_tab'),
        ragService: _ragService,
        onPlantIdentified: _onPlantIdentified,
      ),
      ChatScreen(
        key: const PageStorageKey('chat_screen_tab'),
        ragService: _ragService,
        activePlant: _activePlantContext,
      ),
      ExplorerScreen(
        key: const PageStorageKey('explorer_screen_tab'),
        ragService: _ragService,
        onSelectPlantForChat: _onSelectPlantForChat,
      ),
    ];

    final navDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.center_focus_weak),
        selectedIcon: Icon(Icons.center_focus_strong),
        label: Text("Identify"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: Text("RAG Chat"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: Text("Explorer"),
      ),
    ];

    final body = Row(
      children: [
        if (isWide) ...[
          // Neumorphic Navigation Rail
          Container(
            color: NeuTheme.surfaceColor(context),
            child: NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: NeuContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(12),
                  blurRadius: 10,
                  offset: const Offset(4, 4),
                  child: Icon(
                    Icons.local_florist,
                    color: NeuTheme.primaryColor(context),
                    size: 28,
                  ),
                ),
              ),
              destinations: navDestinations,
            ),
          ),
          Container(
            width: 1,
            color: NeuTheme.shadowDark(context).withValues(alpha: 0.2),
          ),
        ],
        Expanded(
          child: IndexedStack(
            key: const PageStorageKey('main_persistent_indexed_stack'),
            index: _currentIndex,
            children: screens,
          ),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && mounted) {
          if (!kIsWeb) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco,
                size: 22,
                color: NeuTheme.primaryColor(context),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  isWide
                      ? "Medicinal Plant Identification & RAG"
                      : "🌿 Plant RAG",
                ),
              ),
            ],
          ),
        ),
        body: body,
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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
      ),
    );
  }
}
