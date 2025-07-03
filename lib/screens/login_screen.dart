import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/widgets/custom_text_field.dart';
import 'package:sajin/screens/home_screen.dart';
import 'package:sajin/screens/register_screen.dart';
import 'package:sajin/screens/admin/admin_dashboard_screen.dart';
import 'package:sajin/utils/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário
  bool _isLoading = false; // Estado de carregamento

  // Função para lidar com o login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Ativa o indicador de carregamento
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        if (email == AppConstants.adminEmail && password == AppConstants.adminPassword) {
          // Tenta logar como admin
          final adminUser = await authService.loginAdmin();
          if (adminUser != null) {
            // Exibe a notificação de boas-vindas para o admin
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bem-vindo ao Painel Administrativo!',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating, // Para ser mais visível
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
              ),
            );
            // Navega para o painel administrativo
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              (route) => false, // Remove todas as rotas anteriores
            );
          } else {
            _showSnackBar('Credenciais de administrador inválidas.');
          }
        } else {
          // Tenta logar como usuário normal
          final user = await authService.loginUser(email, password);
          if (user != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // Remove todas as rotas anteriores
            );
          } else {
            _showSnackBar('Email ou senha incorretos.');
          }
        }
      } catch (e) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        setState(() {
          _isLoading = false; // Desativa o indicador de carregamento
        });
      }
    }
  }

  // Exibe um SnackBar com a mensagem
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bem-vindo de volta!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Faça login para continuar explorando os momentos do dia a dia.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                // Campo de email
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email.';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo de senha
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Botão de Entrar
                _isLoading
                    ? const CircularProgressIndicator() // Indicador de carregamento
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Entrar'),
                        ),
                      ),
                const SizedBox(height: 24),
                // Redirecionamento para Registro
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Não tem uma conta? Registre-se aqui.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
