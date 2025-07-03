import 'dart:convert'; // Importar para usar jsonEncode e jsonDecode

final String tablePosts = 'posts'; // Nome da tabela de posts

class PostFields {
  static final List<String> values = [
    id, userId, imagePaths, description, postDate, isVideo // Adicionado isVideo
  ];

  static final String id = 'id';
  static final String userId = 'userId';
  static final String imagePaths = 'imagePaths';
  static final String description = 'description';
  static final String postDate = 'postDate';
  static final String isVideo = 'isVideo'; // Novo campo
}

class Post {
  final int? id;
  final int userId;
  final List<String> imagePaths;
  final String? description;
  final String postDate;
  final bool isVideo; // Novo campo para indicar se é vídeo
  String? username;
  String? userProfilePicture;

  Post({
    this.id,
    required this.userId,
    required this.imagePaths,
    this.description,
    required this.postDate,
    this.isVideo = false, // Valor padrão para posts de imagem
    this.username,
    this.userProfilePicture,
  });

  // Converte um Map em um objeto Post
  factory Post.fromMap(Map<String, dynamic> json) => Post(
        id: json[PostFields.id] as int?,
        userId: json[PostFields.userId] as int,
        imagePaths: List<String>.from(jsonDecode(json[PostFields.imagePaths] as String)),
        description: json[PostFields.description] as String?,
        postDate: json[PostFields.postDate] as String,
        isVideo: json[PostFields.isVideo] == 1, // Converte int para bool
        username: json['username'] as String?,
        userProfilePicture: json['userProfilePicture'] as String?,
      );

  // Converte um objeto Post em um Map
  Map<String, dynamic> toMap() => {
        PostFields.id: id,
        PostFields.userId: userId,
        PostFields.imagePaths: jsonEncode(imagePaths),
        PostFields.description: description,
        PostFields.postDate: postDate,
        PostFields.isVideo: isVideo ? 1 : 0, // Converte bool para int
      };

  // Copia um objeto Post com novos valores
  Post copy({
    int? id,
    int? userId,
    List<String>? imagePaths,
    String? description,
    String? postDate,
    bool? isVideo, // Adicionado ao copy
    String? username,
    String? userProfilePicture,
  }) =>
      Post(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        imagePaths: imagePaths ?? this.imagePaths,
        description: description ?? this.description,
        postDate: postDate ?? this.postDate,
        isVideo: isVideo ?? this.isVideo, // Adicionado ao copy
        username: username ?? this.username,
        userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      );
}
