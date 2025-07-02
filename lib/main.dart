import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:sajin/utils/app_theme.dart'; // Importação correta do AppTheme
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/app_constants.dart'; // Importar AppConstants

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o banco de dados ao iniciar o aplicativo
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
    // Escuta as mudanças no tema para reconstruir o MaterialApp
    final appTheme = Provider.of<AppTheme>(context); 

    return MaterialApp(
      title: AppConstants.appName, // Usando o nome do app dos constantes
      debugShowCheckedModeBanner: false,
      themeMode: appTheme.themeMode, // Usa o themeMode do AppTheme
      
      // Tema Claro (Light Theme) - Inspirado nos layouts claros com toques de verde
      theme: ThemeData(
        primarySwatch: Colors.blue, // Manter um primarySwatch para tons de azul
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white, // Fundo branco
        cardColor: Colors.white, // Cards brancos
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.grey[800], displayColor: Colors.grey[900]), // Textos escuros
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // AppBar branca
          foregroundColor: Colors.grey[900], // Ícones e texto da AppBar escuros
          elevation: 0, // Sem sombra na AppBar
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4CAF50), // Verde mais vibrante para seleção
          unselectedItemColor: Colors.grey,
          elevation: 8, // Sombra sutil na barra de navegação
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100], // Fundo de campo levemente cinza
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.0), // Borda verde no foco
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
            backgroundColor: const Color(0xFF4CAF50), // Botões em verde
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50), // Texto e borda em verde
            side: const BorderSide(color: Color(0xFF4CAF50)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey[700], // TextButtons em tom de cinza/azul
          ),
        ),
      ),
      
      // Tema Escuro (Dark Theme) - Inspirado nos layouts escuros com toques de verde
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A202C), // Fundo bem escuro
        cardColor: const Color(0xFF2D3748), // Cards um pouco mais claros que o fundo
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.grey[200], displayColor: Colors.white), // Textos claros
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2D3748), // AppBar escura
          foregroundColor: Colors.white, // Ícones e texto da AppBar claros
          elevation: 0, // Sem sombra na AppBar
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF2D3748),
          selectedItemColor: const Color(0xFF68D391), // Verde mais claro para seleção
          unselectedItemColor: Colors.grey[400],
          elevation: 8, // Sombra sutil
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF4A5568), // Fundo de campo escuro
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF68D391), width: 2.0), // Borda verde no foco
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
            backgroundColor: const Color(0xFF68D391), // Botões em verde claro
            foregroundColor: Colors.black, // Texto preto para contraste
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF68D391), // Texto e borda em verde claro
            side: const BorderSide(color: Color(0xFF68D391)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[300], // TextButtons em tons de cinza claro
          ),
        ),
      ),
      home: const EntryScreen(), // Define a tela de entrada como a tela inicial
    );
  }
}
