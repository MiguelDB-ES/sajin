import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:sajin/utils/app_theme.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';

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
      title: 'Sajin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Define o brilho do tema (claro ou escuro)
        brightness: appTheme.isDarkMode ? Brightness.dark : Brightness.light, 
        // Define a fonte padrão para o aplicativo
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme), 
        appBarTheme: AppBarTheme(
          backgroundColor: appTheme.isDarkMode ? Colors.grey[850] : Colors.blue,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: appTheme.isDarkMode ? Colors.grey[900] : Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
        cardColor: appTheme.isDarkMode ? Colors.grey[800] : Colors.white,
        scaffoldBackgroundColor: appTheme.isDarkMode ? Colors.black : Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: appTheme.isDarkMode ? Colors.grey[700] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Cor de fundo do botão
            foregroundColor: Colors.white, // Cor do texto do botão
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const EntryScreen(), // Define a tela de entrada como a tela inicial
    );
  }
}
