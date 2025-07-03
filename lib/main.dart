import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:sajin/utils/app_theme.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppTheme()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);

    // Novas cores base para o design verde
    const Color primaryGreenLight = Color(0xFF4CAF50); // Um verde vibrante para o tema claro
    const Color primaryGreenDark = Color(0xFF047857); // Um verde mais escuro para o tema escuro
    const Color darkBackground = Color(0xFF121212); // Fundo quase preto
    const Color darkSurface = Color(0xFF1E1E1E); // Superfície escura (cards, etc.)
    const Color lightBackground = Colors.white; // Fundo branco
    const Color lightSurface = Colors.white; // Superfície clara (cards, etc.)
    const Color lightText = Colors.white; // Texto claro
    const Color darkText = Colors.black; // Texto escuro

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: appTheme.themeMode,

      // Tema Claro (Light Theme) - Agora com tons de verde
      theme: ThemeData(
        primarySwatch: Colors.green, // Alterado para green
        primaryColor: primaryGreenLight, // Usar o verde vibrante como cor primária
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        cardColor: lightSurface,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: darkText, displayColor: darkText),
        appBarTheme: AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: lightSurface,
          selectedItemColor: primaryGreenLight, // Verde vibrante para seleção
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryGreenLight, width: 2.0), // Borda verde no foco
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreenLight, // Botões em verde vibrante
            foregroundColor: lightText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreenLight, // Texto e borda em verde vibrante
            side: const BorderSide(color: primaryGreenLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryGreenLight, // TextButtons em verde vibrante
          ),
        ),
      ),

      // Tema Escuro (Dark Theme) - Agora com tons de verde
      darkTheme: ThemeData(
        primarySwatch: Colors.green, // Alterado para green
        primaryColor: primaryGreenDark, // Usar o verde escuro como cor primária no dark mode
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkSurface,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: lightText, displayColor: lightText),
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: lightText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lightText,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: primaryGreenDark, // Verde escuro para seleção
          unselectedItemColor: Colors.grey[400],
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D), // Fundo de campo escuro
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryGreenDark, width: 2.0), // Borda verde no foco
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.grey[300]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreenDark, // Botões em verde escuro
            foregroundColor: darkText, // Texto escuro para contraste
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreenDark, // Texto e borda em verde escuro
            side: const BorderSide(color: primaryGreenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryGreenDark, // TextButtons em verde escuro
          ),
        ),
      ),
      home: const EntryScreen(),
    );
  }
}
