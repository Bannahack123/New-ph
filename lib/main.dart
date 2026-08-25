import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pharoah_manager.dart';
import 'login_view.dart';
import 'gateway/multi_setup_view.dart';
import 'gateway/company_list_screen.dart';
import 'gateway/company_control_panel.dart';
import 'main_control_shell.dart';
import 'web_live_sync/web_portal_gateway.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PharoahManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      final ph = Provider.of<PharoahManager>(context, listen: false);
      ph.handleAppLifecycle(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharoahManager>(
      builder: (context, ph, child) {
        return MaterialApp(
          key: ValueKey(ph.activeCompany?.id ?? "root"), 
          title: 'Pharoah ERP',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
            cardTheme: const CardThemeData(
              elevation: 3,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false, 
              elevation: 0,
              backgroundColor: Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
          ),
          home: Listener(
            onPointerDown: (_) => ph.resetInactivityTimer(),
            onPointerMove: (_) => ph.resetInactivityTimer(),
            child: Stack(
              children: [
                const AppGateway(),
                if (!kIsWeb && ph.isAppLocked && ph.isAdminAuthenticated)
                  const LockOverlayParda(),
              ],
            ),
          ),
        );
      }
    );
  }
}

class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌐 WEB BROWSER DETECT: Agar Web par open hai toh direct Web Portal Station open hoga
    if (kIsWeb) {
      return const WebPortalGateway();
    }

    // 📱 MOBILE / APK ENVIRONMENT: Normal App flow
    final ph = Provider.of<PharoahManager>(context);

    if (ph.companiesRegistry.isEmpty) {
      return const MultiSetupView(isFirstRun: true);
    }
    if (ph.activeCompany == null) {
      return const CompanyListScreen();
    }
    if (!ph.isAdminAuthenticated) {
      return const LoginView();
    }
    if (ph.currentFY.isEmpty) {
      return const CompanyControlPanelView();
    }

    return const MainControlShell();
  }
}

class LockOverlayParda extends StatelessWidget {
  const LockOverlayParda({super.key});

  @override
  Widget build(BuildContext context) {
    final ph = Provider.of<PharoahManager>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text("SESSION LOCKED", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text("Inactivity for ${ph.activeCompany?.autoLockMinutes} minutes", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  onPressed: () => ph.authenticateBiometric(),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("TAP TO UNLOCK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => ph.authenticateAdmin(false),
                  child: const Text("Use Password Instead", style: TextStyle(color: Colors.white54))
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
