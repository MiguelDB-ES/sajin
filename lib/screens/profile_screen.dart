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
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; // Importação do pacote shimmer

class ProfileScreen extends StatefulWidget {
  final int? userId; // ID do utilizador para exibir o perfil (se for o próprio utilizador, será o ID do logado)
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
  User? _displayUser; // Utilizador cujo perfil está a ser exibido
  List<Post> _userPosts = []; // Posts do utilizador
  List<Post> _savedPosts = []; // Posts guardados pelo utilizador
  bool _isLoadingUser = true; // Estado de carregamento do utilizador
  bool _isLoadingPosts = true; // Estado de carregamento dos posts
  bool _isLoadingSavedPosts = true; // Estado de carregamento dos posts guardados
  late TabController _tabController; // Controlador para as abas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Duas abas: Minhas Publicações e Guardadas
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

    // Simula um atraso para ver o shimmer effect
    await Future.delayed(const Duration(seconds: 1));

    if (userToDisplay != null) {
      setState(() {
        _displayUser = userToDisplay;
      });
      await _fetchUserPosts(userToDisplay.id!);
      await _fetchSavedPosts(userToDisplay.id!);
    } else {
      // Tratar caso o utilizador não seja encontrado ou não esteja logado
      print('Utilizador não encontrado ou não logado.');
    }

    setState(() {
      _isLoadingUser = false;
    });
  }

  // Busca os posts do utilizador
  Future<void> _fetchUserPosts(int userId) async {
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final posts = await dbHelper.getPostsByUserId(userId);
      // Para cada post, anexa as informações do utilizador
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
      print('Erro ao carregar posts do utilizador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar publicações do perfil.')),
      );
    } finally {
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  // Busca os posts guardados pelo utilizador
  Future<void> _fetchSavedPosts(int userId) async {
    setState(() {
      _isLoadingSavedPosts = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final savedPosts = await dbHelper.getSavedPosts(userId);
      // Para cada post guardado, anexa as informações do utilizador original do post
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
      print('Erro ao carregar posts guardados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar publicações guardadas.')),
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
        // Usar o método para atualizar o utilizador no AuthService
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
          const SnackBar(content: Text('Erro ao guardar a imagem.')),
        );
      }
    }
  }

  // Navega para a tela de adicionar imagem (mantido para referência, mas o botão foi removido)
  void _navigateToAddImage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPhotoScreen(
          onPostAdded: () {
            _fetchUserPosts(_displayUser!.id!); // Recarrega os posts do utilizador após adicionar um novo
            if (widget.onPostDeleted != null) {
              widget.onPostDeleted!(); // Notifica o feed principal
            }
          },
        ),
      ),
    );
  }

  // Widget de placeholder para o cabeçalho do perfil (Shimmer Effect)
  Widget _buildShimmerProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 180,
              height: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // O Shimmer para o botão "Adicionar Imagem" também foi removido
        ],
      ),
    );
  }

  // Widget de placeholder para o PostCard (Shimmer Effect)
  Widget _buildShimmerPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Cor de fundo do card
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 280,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUserProfile = _displayUser?.id == authService.currentUser?.id;

    return _isLoadingUser
        ? Column(
            children: [
              _buildShimmerProfileHeader(), // Shimmer para o cabeçalho do perfil
              const Divider(),
              TabBar( // TabBar ainda visível, mas sem conteúdo carregado
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Minhas Publicações'),
                  Tab(text: 'Guardadas'),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 3, // Exibe 3 shimmer cards enquanto carrega
                  itemBuilder: (context, index) => _buildShimmerPostCard(),
                ),
              ),
            ],
          )
        : _displayUser == null
            ? const Center(child: Text('Utilizador não encontrado.'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        // Foto de perfil
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              backgroundImage: _displayUser!.profilePicture != null && File(_displayUser!.profilePicture!).existsSync()
                                  ? FileImage(File(_displayUser!.profilePicture!))
                                  : null,
                              child: _displayUser!.profilePicture == null || !File(_displayUser!.profilePicture!).existsSync()
                                  ? Text(
                                      _displayUser!.username[0].toUpperCase(),
                                      style: GoogleFonts.inter(color: Theme.of(context).primaryColor, fontSize: 36, fontWeight: FontWeight.bold),
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
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.camera_alt_rounded, color: Theme.of(context).cardColor, size: 18),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Nome de utilizador
                        Text(
                          _displayUser!.username,
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _displayUser!.fullName,
                          style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7)),
                        ),
                        // O SizedBox de altura 24 e o ElevatedButton.icon para "Adicionar Imagem" foram removidos daqui
                      ],
                    ),
                  ),
                  const Divider(),
                  // Abas de Minhas Publicações e Guardadas
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'Minhas Publicações'),
                      Tab(text: 'Guardadas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Minhas Publicações
                        _isLoadingPosts
                            ? ListView.builder(
                                itemCount: 3,
                                itemBuilder: (context, index) => _buildShimmerPostCard(),
                              )
                            : _userPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported_rounded, size: 80, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCurrentUserProfile
                                              ? 'Ainda não tem nenhuma publicação.'
                                              : 'Este utilizador ainda não tem nenhuma publicação.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
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
                                        showDeleteButton: isCurrentUserProfile, // Permite apagar se for o próprio perfil
                                        onPostDeleted: () {
                                          _fetchUserPosts(_displayUser!.id!); // Recarrega os posts após eliminação
                                          if (widget.onPostDeleted != null) {
                                            widget.onPostDeleted!(); // Notifica o feed principal
                                          }
                                        },
                                      );
                                    },
                                  ),
                        // Posts Guardados
                        _isLoadingSavedPosts
                            ? ListView.builder(
                                itemCount: 3,
                                itemBuilder: (context, index) => _buildShimmerPostCard(),
                              )
                            : _savedPosts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bookmark_border_rounded, size: 80, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCurrentUserProfile
                                              ? 'Ainda não guardou nenhuma publicação.'
                                              : 'Este utilizador ainda não guardou nenhuma publicação.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
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
