import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/models/post.dart'; // Certifique-se de que esta importação está presente e correta

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init(); // Instância singleton
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!; // Retorna o banco de dados se já estiver inicializado
    _database = await _initDB('sajin.db'); // Inicializa o banco de dados
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // Obtém o caminho do diretório do banco de dados
    final path = join(dbPath, filePath); // Junta o caminho do diretório com o nome do arquivo

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // Chama _createDB quando o banco de dados é criado
    );
  }

  Future _createDB(Database db, int version) async {
    // Cria a tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        profilePicture TEXT,
        isAdmin INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Cria a tabela de posts
    // ALTERADO: imagePath para imagePaths TEXT NOT NULL
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        imagePaths TEXT NOT NULL,
        description TEXT,
        postDate TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Cria a tabela de comentários
    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        commentText TEXT NOT NULL,
        commentDate TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Cria a tabela de posts salvos
    await db.execute('''
      CREATE TABLE saved_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        postId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE,
        UNIQUE (userId, postId)
      )
    ''');
  }

  // Métodos CRUD para Usuários
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap()); // Insere um novo usuário
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: UserFields.values,
      where: '${UserFields.email} = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first); // Retorna o usuário se encontrado
    } else {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: UserFields.values,
      where: '${UserFields.username} = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first); // Retorna o usuário se encontrado
    } else {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: UserFields.values,
      where: '${UserFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first); // Retorna o usuário se encontrado
    } else {
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((json) => User.fromMap(json)).toList(); // Retorna todos os usuários
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: '${UserFields.id} = ?',
      whereArgs: [user.id],
    ); // Atualiza um usuário existente
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: '${UserFields.id} = ?',
      whereArgs: [id],
    ); // Deleta um usuário
  }

  // Métodos CRUD para Posts
  Future<int> createPost(Post post) async {
    final db = await instance.database;
    // O método toMap() do Post agora já converte imagePaths para JSON
    return await db.insert('posts', post.toMap()); // Insere um novo post
  }

  Future<List<Post>> getAllPosts() async {
    final db = await instance.database;
    // Corrigido para usar PostFields.postDate
    final result = await db.query('posts', orderBy: '${PostFields.postDate} DESC');
    // O método fromMap() do Post agora já converte a string JSON de imagePaths para List<String>
    return result.map((json) => Post.fromMap(json)).toList(); // Retorna todos os posts
  }

  Future<List<Post>> getPostsByUserId(int userId) async {
    final db = await instance.database;
    // Corrigido para usar PostFields.userId e PostFields.postDate
    final result = await db.query(
      'posts',
      where: '${PostFields.userId} = ?',
      whereArgs: [userId],
      orderBy: '${PostFields.postDate} DESC',
    );
    // O método fromMap() do Post agora já converte a string JSON de imagePaths para List<String>
    return result.map((json) => Post.fromMap(json)).toList(); // Retorna posts de um usuário específico
  }

  Future<int> deletePost(int id) async {
    final db = await instance.database;
    // Corrigido para usar PostFields.id
    return await db.delete(
      'posts',
      where: '${PostFields.id} = ?',
      whereArgs: [id],
    ); // Deleta um post
  }

  // Métodos CRUD para Comentários
  Future<int> createComment(Map<String, dynamic> comment) async {
    final db = await instance.database;
    return await db.insert('comments', comment); // Insere um novo comentário
  }

  Future<List<Map<String, dynamic>>> getCommentsForPost(int postId) async {
    final db = await instance.database;
    // Retorna comentários para um post específico, juntando com informações do usuário
    return await db.rawQuery('''
      SELECT comments.*, users.username, users.profilePicture
      FROM comments
      INNER JOIN users ON comments.userId = users.id
      WHERE comments.postId = ?
      ORDER BY comments.commentDate ASC
    ''', [postId]);
  }

  Future<int> deleteComment(int commentId) async {
    final db = await instance.database;
    return await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
    ); // Deleta um comentário
  }

  // Métodos CRUD para Posts Salvos
  Future<int> savePost(int userId, int postId) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'saved_posts',
        {'userId': userId, 'postId': postId},
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora se o post já estiver salvo
      );
    } catch (e) {
      print('Erro ao salvar post: $e');
      return -1; // Retorna -1 em caso de erro
    }
  }

  Future<int> unsavePost(int userId, int postId) async {
    final db = await instance.database;
    return await db.delete(
      'saved_posts',
      where: 'userId = ? AND postId = ?',
      whereArgs: [userId, postId],
    ); // Desfaz o salvamento de um post
  }

  Future<List<Post>> getSavedPosts(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT posts.* FROM posts
      INNER JOIN saved_posts ON posts.id = saved_posts.postId
      WHERE saved_posts.userId = ?
      ORDER BY posts.postDate DESC
    ''', [userId]);
    // O método fromMap() do Post agora já converte a string JSON de imagePaths para List<String>
    return result.map((json) => Post.fromMap(json)).toList(); // Retorna posts salvos por um usuário
  }

  Future<bool> isPostSaved(int userId, int postId) async {
    final db = await instance.database;
    final result = await db.query(
      'saved_posts',
      where: 'userId = ? AND postId = ?',
      whereArgs: [userId, postId],
    );
    return result.isNotEmpty; // Retorna true se o post estiver salvo
  }

  // Fechar o banco de dados
  Future close() async {
    final db = await instance.database;
    _database = null; // Zera a instância do banco de dados
    db.close(); // Fecha o banco de dados
  }
}
