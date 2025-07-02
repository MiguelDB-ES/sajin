import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajin/models/post.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/widgets/post_card.dart';
import 'package:sajin/screens/add_photo_screen.dart';
import 'package:sajin/services/image_picker_service.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final int? userId; // ID do usuário para exibir o perfil (se for o próprio usuário, será o ID do logado)
  final VoidCallback? onProfileUpdated; // Callback para notificar atualização de perfil
  final VoidCallback? onPostDeleted; // Callback para notificar exclusão de post

  const ProfileScreen({
    super.key,
    this.userId,
    this.onProfileUpdated,
    this.onPostDeleted,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  User? _displayUser; // Usuário cujo perfil está sendo exibido
  List<Post> _userPosts = []; // Posts do usuário
  List<Post> _savedPosts = []; // Posts salvos pelo usuário
  bool _isLoadingUser = true; // Estado de carregamento do usuário
  bool _isLoadingPosts = true; // Estado de carregamento dos posts
  bool _isLoadingSavedPosts = true; // Estado de carregamento dos posts salvos
  late TabController _tabController; // Controlador para as abas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Duas abas: Minhas Postagens e Salvas
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Carrega os dados do perfil e posts
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoadingUser = true;
      _isLoadingPosts = true;
      _isLoadingSavedPosts = true;
    });

    final dbHelper = DatabaseHelper.instance;
    final authService = Provider.of<AuthService>(context, listen: false);

    User? userToDisplay;
    if (widget.userId != null) {
      userToDisplay = await dbHelper.getUserById(widget.userId!);
    } else {
      userToDisplay = authService.currentUser;
    }

    if (userToDisplay != null) {
      setState(() {
        _displayUser = userToDisplay;
      });
      await _fetchUserPosts(userToDisplay.id!);
      await _fetchSavedPosts(userToDisplay.id!);
    } else {
      // Tratar caso o usuário não seja encontrado ou não esteja logado
      print('Usuário não encontrado ou não logado.');
    }

    setState(() {
      _isLoadingUser = false;
    });
  }

  // Busca os posts do usuário
  Future<void> _fetchUserPosts(int userId) async {
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final posts = await dbHelper.getPostsByUserId(userId);
      // Para cada post, anexa as informações do usuário
      List<Post> postsWithUsers = [];
      for (var post in posts) {
        final user = await dbHelper.getUserById(post.userId);
        if (user != null) {
          postsWithUsers.add(post.copy(
            username: user.username,
            userProfilePicture: user.profilePicture,
          ));
        }
      }
      setState(() {
        _userPosts = postsWithUsers;
      });
    } catch (e) {
      print('Erro ao carregar posts do usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar postagens do perfil.')),
      );
    } finally {
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  // Busca os posts salvos pelo usuário
  Future<void> _fetchSavedPosts(int userId) async {
    setState(() {
      _isLoadingSavedPosts = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final savedPosts = await dbHelper.getSavedPosts(userId);
      // Para cada post salvo, anexa as informações do usuário original do post
      List<Post> savedPostsWithUsers = [];
      for (var post in savedPosts) {
        final user = await dbHelper.getUserById(post.userId);
        if (user != null) {
          savedPostsWithUsers.add(post.copy(
            username: user.username,
            userProfilePicture: user.profilePicture,
          ));
        }
      }
      setState(() {
        _savedPosts = savedPostsWithUsers;
      });
    } catch (e) {
      print('Erro ao carregar posts salvos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar postagens salvas.')),
      );
    } finally {
      setState(() {
        _isLoadingSavedPosts = false;
      });
    }
  }

  // Atualiza a foto de perfil
  Future<void> _updateProfilePicture() async {
    final imagePickerService = ImagePickerService();
    final pickedFile = await imagePickerService.pickImageFromGallery();

    if (pickedFile != null && _displayUser != null) {
      final savedPath = await imagePickerService.saveImageLocally(pickedFile);
      if (savedPath != null) {
        final updatedUser = _displayUser!.copy(profilePicture: savedPath);
        await DatabaseHelper.instance.updateUser(updatedUser);
        // Usar o método para atualizar o usuário no AuthService
        Provider.of<AuthService>(context, listen: false).updateCurrentUser(updatedUser); 
        setState(() {
          _displayUser = updatedUser;
        });
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!(); // Notifica a tela pai sobre a atualização
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar a imagem.')),
        );
      }
    }
  }

  // Navega para a tela de adicionar imagem
  void _navigateToAddImage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPhotoScreen(
          onPostAdded: () {
            _fetchUserPosts(_displayUser!.id!); // Recarrega os posts do usuário após adicionar um novo
            if (widget.onPostDeleted != null) {
              widget.onPostDeleted!(); // Notifica o feed principal
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUserProfile = _displayUser?.id == authService.currentUser?.id;

    return _isLoadingUser
        ? const Center(child: CircularProgressIndicator())
        : _displayUser == null
            ? const Center(child: Text('Usuário não encontrado.'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Foto de perfil
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue,
                              backgroundImage: _displayUser!.profilePicture != null && File(_displayUser!.profilePicture!).existsSync()
                                  ? FileImage(File(_displayUser!.profilePicture!))
                                  : null,
                              child: _displayUser!.profilePicture == null || !File(_displayUser!.profilePicture!).existsSync()
                                  ? Text(
                                      _displayUser!.username[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 40),
                                    )
                                  : null,
                            ),
                            if (isCurrentUserProfile)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _updateProfilePicture,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Nome de usuário
                        Text(
                          _displayUser!.username,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _displayUser!.fullName,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        if (isCurrentUserProfile)
                          ElevatedButton.icon(
                            onPressed: _navigateToAddImage,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Adicionar Imagem'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Abas de Minhas Postagens e Salvas
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: const [
                      Tab(text: 'Minhas Postagens'),
                      Tab(text: 'Salvas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Minhas Postagens
                        _isLoadingPosts
                            ? const Center(child: CircularProgressIndicator())
                            : _userPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCurrentUserProfile
                                              ? 'Você ainda não tem nenhuma postagem.'
                                              : 'Este usuário ainda não tem nenhuma postagem.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _userPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _userPosts[index];
                                      return PostCard(
                                        post: post,
                                        showDeleteButton: isCurrentUserProfile, // Permite deletar se for o próprio perfil
                                        onPostDeleted: () {
                                          _fetchUserPosts(_displayUser!.id!); // Recarrega os posts após exclusão
                                          if (widget.onPostDeleted != null) {
                                            widget.onPostDeleted!(); // Notifica o feed principal
                                          }
                                        },
                                      );
                                    },
                                  ),
                        // Posts Salvos
                        _isLoadingSavedPosts
                            ? const Center(child: CircularProgressIndicator())
                            : _savedPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCurrentUserProfile
                                              ? 'Você ainda não salvou nenhuma postagem.'
                                              : 'Este usuário ainda não salvou nenhuma postagem.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _savedPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _savedPosts[index];
                                      return PostCard(post: post);
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              );
  }
}
