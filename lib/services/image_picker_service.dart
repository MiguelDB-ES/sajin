import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Seleciona uma imagem da galeria
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path); // Retorna o arquivo da imagem selecionada
    }
    return null;
  }

  // Tira uma foto com a câmera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return File(image.path); // Retorna o arquivo da imagem tirada
    }
    return null;
  }

  // Salva a imagem no diretório de documentos do aplicativo
  Future<String?> saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory(); // Obtém o diretório de documentos do aplicativo
      final fileName = p.basename(imageFile.path); // Obtém o nome do arquivo da imagem
      final newPath = p.join(appDir.path, fileName); // Cria o novo caminho para o arquivo

      final newImage = await imageFile.copy(newPath); // Copia a imagem para o novo caminho
      return newImage.path; // Retorna o caminho da imagem salva
    } catch (e) {
      print('Erro ao salvar imagem localmente: $e');
      return null;
    }
  }
}
