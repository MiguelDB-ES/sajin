import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sajin/models/post.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/services/image_picker_service.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart'; // Importar para reprodução de vídeo
import 'package:chewie/chewie.dart'; // Importar para controles de vídeo

class AddPhotoScreen extends StatefulWidget {
  final VoidCallback? onPostAdded;

  const AddPhotoScreen({super.key, this.onPostAdded});

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _selectedImages = []; // Lista para imagens
  File? _selectedVideo; // Arquivo para vídeo
  bool _isLoading = false; // Estado de carregamento
  final PageController _pageController = PageController(); // Controlador para o PageView de imagens
  int _currentPage = 0; // Índice da página atual no PageView de imagens

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // Inicializa o controlador de vídeo
  Future<void> _initializeVideoPlayer() async {
    if (_selectedVideo != null) {
      _videoPlayerController = VideoPlayerController.file(_selectedVideo!);
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        showOptions: false, // Esconde o menu de opções padrão
        showControls: true, // Mostra os controles de reprodução
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
        placeholder: Container(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          child: Center(
            child: Icon(Icons.videocam_rounded, size: 60, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
          ),
        ),
      );
      setState(() {}); // Força a reconstrução para exibir o vídeo
    }
  }

  // Seleciona múltiplas imagens da galeria (até 5)
  Future<void> _pickImages() async {
    final List<XFile>? images = await ImagePicker().pickMultiImage(
      imageQuality: 80,
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if (images != null && images.isNotEmpty) {
      final List<File> newImages = images.map((xFile) => File(xFile.path)).toList();
      if (newImages.length > 5) {
        _showSnackBar('Você pode selecionar no máximo 5 fotos.');
        _selectedImages = newImages.sublist(0, 5);
      } else {
        _selectedImages = newImages;
      }
      setState(() {
        _selectedVideo = null; // Limpa o vídeo selecionado
        _videoPlayerController?.dispose();
        _chewieController?.dispose();
        _videoPlayerController = null;
        _chewieController = null;
        _currentPage = 0;
        if (_selectedImages.isNotEmpty) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  // Seleciona um único vídeo da galeria
  Future<void> _pickVideo() async {
    final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedImages = []; // Limpa as imagens selecionadas
      });
      await _initializeVideoPlayer();
    }
  }

  // Publica a mídia (imagens ou vídeo)
  Future<void> _publishPost() async {
    if (_selectedImages.isEmpty && _selectedVideo == null) {
      _showSnackBar('Por favor, selecione pelo menos uma imagem ou um vídeo para publicar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _showSnackBar('Você precisa estar logado para publicar.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      List<String> mediaPaths = [];
      bool isVideoPost = false;

      if (_selectedVideo != null) {
        final savedPath = await _imagePickerService.saveImageLocally(_selectedVideo!); // Reutiliza o método para salvar vídeo
        if (savedPath == null) {
          _showSnackBar('Erro ao salvar o vídeo localmente.');
          return;
        }
        mediaPaths.add(savedPath);
        isVideoPost = true;
      } else {
        for (File image in _selectedImages) {
          final savedPath = await _imagePickerService.saveImageLocally(image);
          if (savedPath == null) {
            _showSnackBar('Erro ao salvar uma das imagens localmente.');
            return;
          }
          mediaPaths.add(savedPath);
        }
      }

      final newPost = Post(
        userId: currentUser.id!,
        imagePaths: mediaPaths,
        description: _descriptionController.text.trim(),
        postDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        isVideo: isVideoPost, // Define se é um vídeo
      );

      await DatabaseHelper.instance.createPost(newPost);

      _showSnackBar('Postagem publicada com sucesso!');
      _descriptionController.clear();
      setState(() {
        _selectedImages = [];
        _selectedVideo = null;
        _currentPage = 0;
        _videoPlayerController?.dispose();
        _chewieController?.dispose();
        _videoPlayerController = null;
        _chewieController = null;
      });

      if (widget.onPostAdded != null) {
        widget.onPostAdded!();
      }
    } catch (e) {
      _showSnackBar('Erro ao publicar postagem: $e');
      print('Erro de publicação: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Postagem'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área para seleção e exibição de mídia
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2),
                ),
                child: _selectedVideo != null
                    ? (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Chewie(
                              controller: _chewieController!,
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()))
                    : (_selectedImages.isNotEmpty
                        ? Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 10,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_selectedImages.length, (index) {
                                    return Container(
                                      width: 8.0,
                                      height: 8.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == index
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.withOpacity(0.5),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 60, color: Theme.of(context).primaryColor.withOpacity(0.7)),
                              const SizedBox(height: 12),
                              Text(
                                'Toque para anexar foto(s) ou vídeo',
                                style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7), fontSize: 16),
                              ),
                            ],
                          )),
              ),
              const SizedBox(height: 16),
              // Botões de seleção de mídia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Fotos (até 5)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_rounded),
                      label: const Text('Vídeo (1)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Campo para descrição
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Adicionar descrição...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                ),
                style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 32),
              // Botão de Publicar
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _publishPost,
                      child: const Text('Publicar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
