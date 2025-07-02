final String tableUsers = 'users'; // Nome da tabela de usuários

class UserFields {
  static final List<String> values = [
    id, fullName, email, password, dateOfBirth, username, profilePicture, isAdmin, isActive
  ];

  static final String id = 'id';
  static final String fullName = 'fullName';
  static final String email = 'email';
  static final String password = 'password';
  static final String dateOfBirth = 'dateOfBirth';
  static final String username = 'username';
  static final String profilePicture = 'profilePicture'; // Caminho para a imagem de perfil
  static final String isAdmin = 'isAdmin'; // 0 para usuário normal, 1 para admin
  static final String isActive = 'isActive'; // 0 para inativo, 1 para ativo
}

class User {
  final int? id;
  final String fullName;
  final String email;
  final String password;
  final String dateOfBirth;
  final String username;
  final String? profilePicture;
  final bool isAdmin;
  final bool isActive;

  const User({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.dateOfBirth,
    required this.username,
    this.profilePicture,
    this.isAdmin = false,
    this.isActive = true,
  });

  // Converte um Map em um objeto User
  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json[UserFields.id] as int?,
        fullName: json[UserFields.fullName] as String,
        email: json[UserFields.email] as String,
        password: json[UserFields.password] as String,
        dateOfBirth: json[UserFields.dateOfBirth] as String,
        username: json[UserFields.username] as String,
        profilePicture: json[UserFields.profilePicture] as String?,
        isAdmin: json[UserFields.isAdmin] == 1,
        isActive: json[UserFields.isActive] == 1,
      );

  // Converte um objeto User em um Map
  Map<String, dynamic> toMap() => {
        UserFields.id: id,
        UserFields.fullName: fullName,
        UserFields.email: email,
        UserFields.password: password,
        UserFields.dateOfBirth: dateOfBirth,
        UserFields.username: username,
        UserFields.profilePicture: profilePicture,
        UserFields.isAdmin: isAdmin ? 1 : 0,
        UserFields.isActive: isActive ? 1 : 0,
      };

  // Copia um objeto User com novos valores
  User copy({
    int? id,
    String? fullName,
    String? email,
    String? password,
    String? dateOfBirth,
    String? username,
    String? profilePicture,
    bool? isAdmin,
    bool? isActive,
  }) =>
      User(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        password: password ?? this.password,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        username: username ?? this.username,
        profilePicture: profilePicture ?? this.profilePicture,
        isAdmin: isAdmin ?? this.isAdmin,
        isActive: isActive ?? this.isActive,
      );
}
