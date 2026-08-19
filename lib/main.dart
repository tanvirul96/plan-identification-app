import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_locale.dart';
import 'services/history_service.dart';
import 'services/localization_service.dart';
import 'services/rag_service.dart';
import 'services/theme_service.dart';
import 'screens/clinical_hub_screen.dart';
import 'screens/identify_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/explorer_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/neu_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService().init();
  await HistoryService().init();
  await ThemeService().init();
  runApp(const PlantIdentificationApp());
}

class PlantIdentificationApp extends StatelessWidget {
  const PlantIdentificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: LocalizationService().currentLanguage,
          builder: (context, lang, _) {
            return MaterialApp(
              title: lang == AppLanguage.bangla
                  ? 'ভেষজ উদ্ভিদ শনাক্তকরণ ও ক্লিনিক্যাল RAG'
                  : 'Medicinal Plant ID & Clinical RAG',
              debugShowCheckedModeBanner: false,

              // ── Neumorphism Light Theme (Botanical Sage Green) ──
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
                    fontSize: 17,
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
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: NeuTheme.lightOnSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: NeuTheme.lightBg,
                  indicatorColor: NeuTheme.lightPrimary.withValues(alpha: 0.18),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: NeuTheme.lightPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      );
                    }
                    return TextStyle(
                      color: NeuTheme.lightOnSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    );
                  }),
                ),
              ),

              // ── Neumorphism Dark Theme (Deep Rainforest Green) ──
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
                    fontSize: 17,
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
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: NeuTheme.darkOnSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: NeuTheme.darkBg,
                  indicatorColor: NeuTheme.darkPrimary.withValues(alpha: 0.18),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: NeuTheme.darkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      );
                    }
                    return TextStyle(
                      color: NeuTheme.darkOnSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    );
                  }),
                ),
              ),

              themeMode: currentThemeMode,
              home: const MainHomeScreen(),
            );
          },
        );
      },
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
  final LocalizationService _loc = LocalizationService();
  final ThemeService _themeService = ThemeService();
  String? _activePlantContext;

  void _onPlantIdentified(String plantName) {
    setState(() {
      _activePlantContext = plantName;
    });
  }

  void _onSelectPlantForChat(String plantName) {
    setState(() {
      _activePlantContext = plantName;
      _currentIndex = 2; // Switch to Chat tab
    });
  }

  void _onSelectPlantForClinical(String plantName) {
    setState(() {
      _activePlantContext = plantName;
      _currentIndex = 1; // Switch to Clinical Hub tab
    });
  }

  Future<bool> _onWillPop() async {
    if (kIsWeb) return true;
    final isBn = _loc.isBangla;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: NeuTheme.primaryColor(context)),
            const SizedBox(width: 12),
            Text(isBn ? "অ্যাপ বন্ধ করবেন?" : "Exit App"),
          ],
        ),
        content: Text(isBn
            ? "আপনি কি নিশ্চিতভাবে অ্যাপ থেকে বের হতে চান?"
            : "Are you sure you want to exit the application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              isBn ? "থাকুন" : "Stay",
              style: TextStyle(
                color: NeuTheme.primaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isBn ? "বের হন" : "Exit",
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void _showThemeSelector(BuildContext context) {
    final isBn = _loc.isBangla;
    showModalBottomSheet(
      context: context,
      backgroundColor: NeuTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Text(
                  isBn ? "🎨 থিম নির্বাচন করুন" : "🎨 Select Appearance Theme",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NeuTheme.onSurface(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildThemeTile(ctx, ThemeMode.light, Icons.light_mode, isBn ? "লাইট মোড (Light Mode)" : "Light Mode", Colors.amber.shade700),
              _buildThemeTile(ctx, ThemeMode.dark, Icons.dark_mode, isBn ? "ডার্ক মোড (Dark Mode)" : "Dark Mode", Colors.indigoAccent),
              _buildThemeTile(ctx, ThemeMode.system, Icons.brightness_auto, isBn ? "সিস্টেম অটো (System Auto)" : "System Default", NeuTheme.primaryColor(context)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeTile(BuildContext ctx, ThemeMode mode, IconData icon, String title, Color iconColor) {
    final isSelected = _themeService.themeModeNotifier.value == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          _themeService.setThemeMode(mode);
          Navigator.of(ctx).pop();
        },
        child: NeuContainer(
          isPressed: isSelected,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    color: NeuTheme.onSurface(context),
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: NeuTheme.primaryColor(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 850;
    final isBn = _loc.isBangla;

    final screens = [
      IdentifyScreen(
        key: const PageStorageKey('identify_screen_tab'),
        ragService: _ragService,
        onPlantIdentified: _onPlantIdentified,
      ),
      ClinicalHubScreen(
        key: const PageStorageKey('clinical_hub_tab'),
        ragService: _ragService,
        initialPlant: _activePlantContext,
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
        onSelectPlantForClinical: _onSelectPlantForClinical,
      ),
      HistoryScreen(
        key: const PageStorageKey('history_screen_tab'),
        onSelectPlantForChat: _onSelectPlantForChat,
      ),
    ];

    final navDestinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.center_focus_weak),
        selectedIcon: const Icon(Icons.center_focus_strong),
        label: Text(isBn ? "শনাক্তকরণ" : "Identify"),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.medical_services_outlined),
        selectedIcon: const Icon(Icons.medical_services),
        label: Text(isBn ? "ক্লিনিক্যাল" : "Clinical"),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: Text(isBn ? "RAG চ্যাট" : "RAG Chat"),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: Text(isBn ? "উদ্ভিদকোষ" : "Explorer"),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.history),
        selectedIcon: const Icon(Icons.history_toggle_off),
        label: Text(isBn ? "ইতিহাস" : "History"),
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
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: NeuContainer(
                  borderRadius: 26,
                  padding: const EdgeInsets.all(10),
                  blurRadius: 8,
                  offset: const Offset(3, 3),
                  child: Icon(
                    Icons.eco,
                    color: NeuTheme.primaryColor(context),
                    size: 26,
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
                Icons.local_florist,
                size: 22,
                color: NeuTheme.primaryColor(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isWide
                      ? (isBn
                          ? "ঔষধি উদ্ভিদ শনাক্তকরণ ও ক্লিনিক্যাল RAG অ্যাসিস্ট্যান্ট"
                          : "Medicinal Plant ID & Clinical Pharmacology RAG")
                      : (isBn ? "🌿 ভেষজ উদ্ভিদ RAG" : "🌿 Plant RAG"),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // Theme Mode Selector (☀️ Light, 🌙 Dark, ⚙️ Auto)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _showThemeSelector(context),
                child: NeuContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _themeService.themeIcon,
                        size: 16,
                        color: NeuTheme.primaryColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _themeService.getThemeName(isBn),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: NeuTheme.onSurface(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bilingual Switcher Button (🇧🇩 বাংলা ↔ 🇬🇧 EN)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () => _loc.toggleLanguage(),
                child: NeuContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _loc.currentLanguage.value.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _loc.currentLanguage.value.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: NeuTheme.primaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.center_focus_weak),
                    selectedIcon: const Icon(Icons.center_focus_strong),
                    label: isBn ? "শনাক্তকরণ" : "Identify",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.medical_services_outlined),
                    selectedIcon: const Icon(Icons.medical_services),
                    label: isBn ? "ক্লিনিক্যাল" : "Clinical",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.chat_bubble_outline),
                    selectedIcon: const Icon(Icons.chat_bubble),
                    label: isBn ? "RAG চ্যাট" : "RAG Chat",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book),
                    label: isBn ? "উদ্ভিদকোষ" : "Explorer",
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history),
                    selectedIcon: const Icon(Icons.history_toggle_off),
                    label: isBn ? "ইতিহাস" : "History",
                  ),
                ],
              ),
      ),
    );
  }
}
