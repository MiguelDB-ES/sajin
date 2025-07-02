import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/utils/app_constants.dart';

class AuthService {
  User? _currentUser; // Usuário atualmente logado

  User? get currentUser => _currentUser;

  // Método para atualizar o usuário logado
  void updateCurrentUser(User? user) {
    _currentUser = user;
  }

  // Realiza o registro de um novo usuário
  Future<bool> registerUser(User user) async {
    final dbHelper = DatabaseHelper.instance;
    // Verifica se já existe um usuário com o mesmo email ou username
    final existingUserByEmail = await dbHelper.getUserByEmail(user.email);
    final existingUserByUsername = await dbHelper.getUserByUsername(user.username);

    if (existingUserByEmail != null) {
      throw Exception('Este email já está em uso.');
    }
    if (existingUserByUsername != null) {
      throw Exception('Este nome de usuário já está em uso.');
    }

    // Insere o usuário no banco de dados
    final id = await dbHelper.createUser(user);
    return id > 0;
  }

  // Realiza o login de um usuário
  Future<User?> loginUser(String email, String password) async {
    final dbHelper = DatabaseHelper.instance;
    // Tenta obter o usuário pelo email
    final user = await dbHelper.getUserByEmail(email);

    if (user != null && user.password == password) {
      if (!user.isActive) {
        throw Exception('Sua conta está desativada. Entre em contato com o administrador.');
      }
      _currentUser = user; // Define o usuário logado
      return user;
    }
    return null; // Retorna null se as credenciais estiverem incorretas
  }

  // Realiza o login do administrador
  Future<User?> loginAdmin() async {
    final dbHelper = DatabaseHelper.instance;
    // Tenta obter o usuário admin pelo email
    User? adminUser = await dbHelper.getUserByEmail(AppConstants.adminEmail);

    // Se o admin não existir, cria-o
    if (adminUser == null) {
      adminUser = const User(
        fullName: 'Administrador Sajin',
        email: AppConstants.adminEmail,
        password: AppConstants.adminPassword,
        dateOfBirth: '01/01/2000', // Data de nascimento padrão
        username: 'admin_sajin',
        isAdmin: true,
      );
      await dbHelper.createUser(adminUser);
      adminUser = await dbHelper.getUserByEmail(AppConstants.adminEmail); // Busca novamente para obter o ID
    }

    if (adminUser != null && adminUser.password == AppConstants.adminPassword) {
      _currentUser = adminUser; // Define o usuário logado como admin
      return adminUser;
    }
    return null;
  }

  // Desloga o usuário
  void logout() {
    _currentUser = null; // Limpa o usuário logado
  }
}
