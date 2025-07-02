final String tablePosts = 'posts'; // Nome da tabela de posts

class PostFields {
  static final List<String> values = [
    id, userId, imagePath, description, postDate
  ];

  static final String id = 'id';
  static final String userId = 'userId';
  static final String imagePath = 'imagePath'; // Caminho local da imagem
  static final String description = 'description';
  static final String postDate = 'postDate';
}

class Post {
  final int? id;
  final int userId;
  final String imagePath;
  final String? description; // Pode ser nulo
  final String postDate;
  String? username; // Adicionado para exibição no feed, pode ser nulo
  String? userProfilePicture; // Adicionado para exibição no feed, pode ser nulo (corrigido de userImage)

  Post({
    this.id,
    required this.userId,
    required this.imagePath,
    this.description, // Não é mais required
    required this.postDate,
    this.username,
    this.userProfilePicture, // Corrigido de userImage
  });

  // Converte um Map em um objeto Post
  factory Post.fromMap(Map<String, dynamic> json) => Post(
        id: json[PostFields.id] as int?,
        userId: json[PostFields.userId] as int,
        imagePath: json[PostFields.imagePath] as String,
        description: json[PostFields.description] as String?,
        postDate: json[PostFields.postDate] as String,
        username: json['username'] as String?, // Pode vir de um JOIN
        userProfilePicture: json['userProfilePicture'] as String?, // Pode vir de um JOIN (corrigido de userImage)
      );

  // Converte um objeto Post em um Map
  Map<String, dynamic> toMap() => {
        PostFields.id: id,
        PostFields.userId: userId,
        PostFields.imagePath: imagePath,
        PostFields.description: description,
        PostFields.postDate: postDate,
      };

  // Copia um objeto Post com novos valores (usado em home_screen e profile_screen)
  Post copy({
    int? id,
    int? userId,
    String? imagePath,
    String? description,
    String? postDate,
    String? username,
    String? userProfilePicture,
  }) =>
      Post(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        imagePath: imagePath ?? this.imagePath,
        description: description ?? this.description,
        postDate: postDate ?? this.postDate,
        username: username ?? this.username,
        userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      );
}
