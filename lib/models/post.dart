import 'dart:convert'; // Importar para usar jsonEncode e jsonDecode

final String tablePosts = 'posts'; // Nome da tabela de posts

class PostFields {
  static final List<String> values = [
    id, userId, imagePaths, description, postDate // Alterado de imagePath para imagePaths
  ];

  static final String id = 'id';
  static final String userId = 'userId';
  static final String imagePaths = 'imagePaths'; // Alterado para imagePaths
  static final String description = 'description';
  static final String postDate = 'postDate';
}

class Post {
  final int? id;
  final int userId;
  final List<String> imagePaths; // Alterado para List<String>
  final String? description; // Pode ser nulo
  final String postDate;
  String? username; // Adicionado para exibição no feed, pode ser nulo
  String? userProfilePicture; // Adicionado para exibição no feed, pode ser nulo

  Post({
    this.id,
    required this.userId,
    required this.imagePaths, // Alterado para List<String>
    this.description, // Não é mais required
    required this.postDate,
    this.username,
    this.userProfilePicture,
  });

  // Converte um Map em um objeto Post
  factory Post.fromMap(Map<String, dynamic> json) => Post(
        id: json[PostFields.id] as int?,
        userId: json[PostFields.userId] as int,
        // Converte a string JSON de imagePaths de volta para List<String>
        imagePaths: List<String>.from(jsonDecode(json[PostFields.imagePaths] as String)),
        description: json[PostFields.description] as String?,
        postDate: json[PostFields.postDate] as String,
        username: json['username'] as String?, // Pode vir de um JOIN
        userProfilePicture: json['userProfilePicture'] as String?, // Pode vir de um JOIN
      );

  // Converte um objeto Post em um Map
  Map<String, dynamic> toMap() => {
        PostFields.id: id,
        PostFields.userId: userId,
        // Converte List<String> de imagePaths para uma string JSON
        PostFields.imagePaths: jsonEncode(imagePaths),
        PostFields.description: description,
        PostFields.postDate: postDate,
      };

  // Copia um objeto Post com novos valores (usado em home_screen e profile_screen)
  Post copy({
    int? id,
    int? userId,
    List<String>? imagePaths, // Alterado para List<String>
    String? description,
    String? postDate,
    String? username,
    String? userProfilePicture,
  }) =>
      Post(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        imagePaths: imagePaths ?? this.imagePaths, // Alterado para List<String>
        description: description ?? this.description,
        postDate: postDate ?? this.postDate,
        username: username ?? this.username,
        userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      );
}
