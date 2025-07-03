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

class AddPhotoScreen extends StatefulWidget {
  final VoidCallback? onPostAdded;

  const AddPhotoScreen({super.key, this.onPostAdded});

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _selectedImages = []; // Alterado para lista de File
  bool _isLoading = false; // Estado de carregamento
  final PageController _pageController = PageController(); // Controlador para o PageView
  int _currentPage = 0; // Índice da página atual no PageView

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Seleciona múltiplas imagens da galeria
  Future<void> _pickImages() async {
    final List<XFile>? images = await ImagePicker().pickMultiImage(); // Usar pickMultiImage
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        _currentPage = 0; // Resetar para a primeira imagem ao selecionar novas
        _pageController.jumpToPage(0); // Pular para a primeira página
      });
    }
  }

  // Publica a imagem
  Future<void> _publishPost() async {
    if (_selectedImages.isEmpty) { // Verificar se a lista de imagens está vazia
      _showSnackBar('Por favor, selecione pelo menos uma imagem para publicar.');
      return;
    }

    setState(() {
      _isLoading = true; // Ativa o indicador de carregamento
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
      List<String> savedImagePaths = [];
      for (File image in _selectedImages) {
        final savedPath = await _imagePickerService.saveImageLocally(image);
        if (savedPath == null) {
          _showSnackBar('Erro ao salvar uma das imagens localmente.');
          return;
        }
        savedImagePaths.add(savedPath);
      }

      // Cria o objeto Post com a lista de caminhos de imagem
      final newPost = Post(
        userId: currentUser.id!,
        imagePaths: savedImagePaths, // Passar a lista de caminhos
        description: _descriptionController.text.trim(),
        postDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );

      // Salva o post no banco de dados
      await DatabaseHelper.instance.createPost(newPost);

      _showSnackBar('Postagem publicada com sucesso!');
      _descriptionController.clear();
      setState(() {
        _selectedImages = []; // Limpa as imagens selecionadas
        _currentPage = 0;
      });

      if (widget.onPostAdded != null) {
        widget.onPostAdded!();
      }
    } catch (e) {
      _showSnackBar('Erro ao publicar postagem: $e');
    } finally {
      setState(() {
        _isLoading = false; // Desativa o indicador de carregamento
      });
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
        title: const Text('Adicionar Foto(s)'), // Título atualizado
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área para exibir as imagens selecionadas (PageView para scroll horizontal)
              GestureDetector(
                onTap: _pickImages, // Chama _pickImages para selecionar múltiplas
                child: Container(
                  height: 250, // Altura ajustada
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16.0), // Bordas mais arredondadas
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2), // Borda sutil
                  ),
                  child: _selectedImages.isNotEmpty
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
                            // Indicadores de página
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
                              'Toque para anexar foto(s)', // Texto atualizado
                              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7), fontSize: 16),
                            ),
                          ],
                        ),
                ),
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
