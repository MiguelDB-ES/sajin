import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/widgets/custom_text_field.dart';
import 'package:sajin/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário
  bool _isLoading = false; // Estado de carregamento

  // Função para selecionar a data de nascimento
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor, // Cor primária do tema
              onPrimary: Theme.of(context).cardColor, // Cor do texto na cor primária
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, // Cor do texto no calendário
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, // Cor dos botões de texto
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Função para lidar com o registro
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('As senhas não coincidem.');
        return;
      }

      setState(() {
        _isLoading = true; // Ativa o indicador de carregamento
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final newUser = User(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        username: _usernameController.text.trim(),
      );

      try {
        final success = await authService.registerUser(newUser);
        if (success) {
          _showSnackBar('Conta criada com sucesso! Faça login para continuar.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          _showSnackBar('Erro ao criar conta. Tente novamente.');
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
        title: const Text('Registrar'),
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
                  'Crie sua conta no Sajin!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Junte-se à nossa comunidade e compartilhe seus momentos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                // Campo Nome Completo
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Nome Completo',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome completo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo Nome de Usuário
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Nome de Usuário',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um nome de usuário.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo Email
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
                // Campo Senha
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha.';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo Confirmar Senha
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmar Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha.';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Campo Data de Nascimento
                CustomTextField(
                  controller: _dateOfBirthController,
                  labelText: 'Data de Nascimento',
                  keyboardType: TextInputType.datetime,
                  readOnly: true, // Impede a edição manual
                  onTap: () => _selectDate(context),
                  suffixIcon: const Icon(Icons.calendar_today),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione sua data de nascimento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Botão de Registrar
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          child: const Text('Criar Conta'),
                        ),
                      ),
                const SizedBox(height: 24),
                // Redirecionamento para Login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Volta para a tela de login
                  },
                  child: const Text(
                    'Já tem uma conta? Faça login.',
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
