import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/plan_studio_provider.dart';
import 'screens/studio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanStudioProvider()),
      ],
      child: const PlaansApp(),
    ),
  );
}

class PlaansApp extends StatefulWidget {
  const PlaansApp({super.key});

  @override
  State<PlaansApp> createState() => _PlaansAppState();
}

class _PlaansAppState extends State<PlaansApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialShareRoute();
    });
  }

  void _checkInitialShareRoute() {
    final uri = Uri.base;
    final fragment = uri.fragment; // e.g., /p/tokyo-72-hours?data=...
    if (fragment.startsWith('/p/')) {
      final fragUri = Uri.tryParse(fragment);
      if (fragUri != null && fragUri.pathSegments.length >= 2) {
        final slug = fragUri.pathSegments[1];
        final data = fragUri.queryParameters['data'];
        context
            .read<PlanStudioProvider>()
            .openSharedPlan(slug, encodedData: data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLAANS — Visual Itinerary & GPS Plan Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF5A36),
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      ),
      home: const StudioScreen(),
    );
  }
}
