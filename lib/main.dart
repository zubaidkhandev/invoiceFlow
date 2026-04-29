import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice_flow/blocs/auth_cubit.dart';
import 'package:invoice_flow/blocs/client_cubit.dart';
import 'package:invoice_flow/blocs/invoice_cubit.dart';
import 'package:invoice_flow/blocs/settings_cubit.dart';
import 'package:invoice_flow/blocs/history_cubit.dart';
import 'package:invoice_flow/services/storage_service.dart';
import 'package:invoice_flow/widgets/app_scaffold.dart';
import 'package:invoice_flow/screens/auth_screen.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthCubit(storageService)),
          BlocProvider(create: (context) => SettingsCubit(storageService)),
          BlocProvider(
              create: (context) => HistoryCubit(storageService)..loadHistory()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  InvoiceCubit(storageService, context.read<HistoryCubit>())
                    ..loadInvoices(),
            ),
            BlocProvider(
              create: (context) =>
                  ClientCubit(storageService, context.read<HistoryCubit>())
                    ..loadClients(),
            ),
          ],
          child: const InvoiceFlowApp(),
        ),
      ),
    ),
  );
}

class InvoiceFlowApp extends StatelessWidget {
  const InvoiceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return MaterialApp(
          title: 'InvoiceFlow',
          debugShowCheckedModeBanner: false,
          themeMode:
              settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthLocked) {
                return const AuthScreen();
              }
              return const AppScaffold();
            },
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primaryYellow = Color(0xFFFED200);
    final primaryColor = isDark ? primaryYellow : const Color(0xFFB45309); // Use deeper amber for light mode visibility
    final scaffoldBg = isDark ? const Color(0xFF030404) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        primary: primaryColor,
        secondary: isDark ? primaryYellow : const Color(0xFFD97706),
        brightness: brightness,
        surface: cardBg,
        surfaceContainerHighest:
            isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardBg,
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF0F172A),
        displayColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade300), // Slightly more visible border
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.blueGrey.shade600),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.blueGrey.shade300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme:
            IconThemeData(color: isDark ? Colors.white54 : Colors.blueGrey.shade300),
        selectedLabelTextStyle:
            TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle:
            TextStyle(color: isDark ? Colors.white54 : Colors.blueGrey.shade300),
      ),
    );
  }
}
