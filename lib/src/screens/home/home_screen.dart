import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;
import '../../controllers/home_controller.dart';
import '../perfil/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  HomeScreen({required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final HomeController _controller = HomeController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  bool showSayByeOptions = false;
  Map<String, bool> expandedOptions = {
    "Express": false,
    "Programed": false,
    "Last Vibe": false,
  };

  late AnimationController _audioIconController;
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _audioIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _audioIconController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioIconController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<Duration?> _getVideoDuration(PlatformFile file) async {
    try {
      if (kIsWeb) {
        // Corrección: Crear Blob con la lista convertida a dynamic
        final blob = web.Blob([file.bytes!] as dynamic);
        final videoUrl = web.URL.createObjectURL(blob);
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
      } else {
        // Implementación para móvil/desktop
        _videoController = VideoPlayerController.file(File(file.path!));
      }

      _initializeVideoPlayerFuture = _videoController!.initialize();
      await _initializeVideoPlayerFuture;

      final duration = _videoController!.value.duration;
      _videoController?.dispose();

      return duration;
    } catch (e) {
      print('Error al obtener duración: $e');
      return null;
    }
  }

  void toggleExpanded(String category) {
    setState(() {
      expandedOptions[category] = !expandedOptions[category]!;
    });
  }

  Future<void> _pickAndUploadFile(String type, String category) async {
    try {
      // Límites configurados
      const maxImageSize = 50 * 1024 * 1024; // 50 MB para imágenes
      const maxAudioSize = 30 * 1024 * 1024; // 30 MB para audio
      const maxVideoDuration = Duration(seconds: 71); // 1 min 11 seg
      const maxVideoSize = 100 * 1024 * 1024; // 100 MB para video
      const maxTextLines = 1000; // 1000 líneas para texto
      const maxTextSize = 5 * 1024 * 1024; // 5 MB para texto

      FilePickerResult? result;
      final isWeb = kIsWeb;

      try {
        switch (type) {
          case 'Audio':
            result = await FilePicker.platform.pickFiles(
              type: isWeb ? FileType.custom : FileType.audio,
              allowedExtensions: isWeb ? ['mp3', 'wav', 'm4a'] : null,
            );
            break;
          case 'Video':
            result = await FilePicker.platform.pickFiles(
              type: isWeb ? FileType.custom : FileType.video,
              allowedExtensions: isWeb ? ['mp4', 'mov', 'avi'] : null,
            );
            break;
          case 'Texto':
            result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['txt', 'doc', 'docx', 'pdf'],
            );
            break;
          case 'Foto':
            result = await FilePicker.platform.pickFiles(
              type: isWeb ? FileType.custom : FileType.image,
              allowedExtensions: isWeb ? ['jpg', 'jpeg', 'png', 'gif'] : null,
            );
            break;
          default:
            return;
        }
      } catch (e) {
        // Fallback si falla la detección de plataforma
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _getAllowedExtensions(type),
        );
      }

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null && !isWeb) return;

      // Validaciones antes de subir
      if (type == 'Foto' && file.size > maxImageSize) {
        throw Exception('Las imágenes no pueden superar los 50MB');
      }

      if (type == 'Audio' && file.size > maxAudioSize) {
        throw Exception('Los audios no pueden superar los 30MB');
      }

      if (type == 'Video') {
        if (file.size > maxVideoSize) {
          throw Exception('Los videos no pueden superar los 100MB');
        }

        final videoDuration = await _getVideoDuration(file);
        if (videoDuration != null && videoDuration > maxVideoDuration) {
          throw Exception('Los videos no pueden superar 1 minuto 11 segundos');
        }
      }

      if (type == 'Texto') {
        if (file.size > maxTextSize) {
          throw Exception('Los archivos de texto no pueden superar 5MB');
        }

        final lineCount = await _countTextLines(file);
        if (lineCount > maxTextLines) {
          throw Exception(
            'Los textos no pueden superar las $maxTextLines líneas',
          );
        }
      }

      // Mostrar progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Validando y subiendo archivo...'),
            ],
          ),
        ),
      );

      try {
        final privateKey = _uuid.v4();
        final publicKey = _uuid.v4();
        final fileName = file.name;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // Validar extensión
        if (!_getAllowedExtensions(type).contains(fileExtension)) {
          throw Exception('Tipo de archivo no válido para $type');
        }

        Reference ref = FirebaseStorage.instance.ref().child(
          'uploads/${widget.user.uid}/$category/$type/$fileName',
        );

        // Subir archivo
        if (isWeb) {
          final bytes = file.bytes;
          if (bytes == null) throw Exception('No se pudo leer el archivo');
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(file.path!));
        }

        final downloadUrl = await ref.getDownloadURL();

        await _firestore.collection('memories').doc(privateKey).set({
          'ownerUid': widget.user.uid,
          'publicKey': publicKey,
          'downloadUrl': downloadUrl,
          'type': type.toLowerCase(),
          'category': category,
          'fileName': fileName,
          'fileSize': file.size,
          'duration': type == 'Video' ? maxVideoDuration.inSeconds : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).pop(); // Cerrar diálogo de progreso
        _showShareOptions(publicKey, downloadUrl);
      } catch (e) {
        Navigator.of(context).pop();
        rethrow;
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  List<String> _getAllowedExtensions(String type) {
    switch (type) {
      case 'Audio':
        return ['mp3', 'wav', 'm4a'];
      case 'Video':
        return ['mp4', 'mov', 'avi'];
      case 'Texto':
        return ['txt', 'doc', 'docx', 'pdf'];
      case 'Foto':
        return ['jpg', 'jpeg', 'png', 'gif'];
      default:
        return [];
    }
  }

  Future<int> _countTextLines(PlatformFile file) async {
    if (file.bytes != null) {
      final content = utf8.decode(file.bytes!);
      return content.split('\n').length;
    } else if (file.path != null) {
      final lines = await File(file.path!).readAsLines();
      return lines.length;
    }
    return 0;
  }

  void _showShareOptions(String publicKey, String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archivo subido con éxito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Llave para compartir:'),
            SelectableText(publicKey),
            SizedBox(height: 20),
            Text('O comparte directamente:'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('WhatsApp'),
            onPressed: () => _shareViaWhatsApp(publicKey),
          ),
          TextButton(
            child: Text('Correo'),
            onPressed: () => _shareViaEmail(publicKey, downloadUrl),
          ),
          TextButton(
            child: Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp(String publicKey) async {
    final url = Uri.parse(
      'https://wa.me/?text=Accede%20a%20mi%20recuerdo%20en%20ByeApp%20con%20esta%20llave:%20$publicKey',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp')));
    }
  }

  Future<void> _shareViaEmail(String publicKey, String downloadUrl) async {
    final subject = 'Te comparto un recuerdo en ByeApp';
    final body =
        '''
Puedes acceder a este recuerdo usando la siguiente llave en ByeApp:
$publicKey

O visita este enlace directo (debes estar logueado):
$downloadUrl
''';

    final url = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el cliente de correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user.displayName?.split(" ").first ?? "Usuario";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 51, 129, 244),
        title: Text(
          'Bienvenido a Bye App',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key, color: Colors.white),
            onPressed: () => _showKeyInputDialog(),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _controller.logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilScreen(user: widget.user),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            Icons.account_circle,
                            size: 80,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 51, 129, 244),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildGradientButton(
                        'Say Bye',
                        () {
                          setState(() {
                            showSayByeOptions = !showSayByeOptions;
                            if (!showSayByeOptions) {
                              expandedOptions.updateAll((key, value) => false);
                            }
                          });
                        },
                        gradientColors: [Color(0xFF337DFF), Color(0xFFFF6E1F)],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: showSayByeOptions
                            ? Column(
                                key: const ValueKey('sayByeOptions'),
                                children: [
                                  const SizedBox(height: 12),
                                  _buildExpandableCategory("Express"),
                                  const SizedBox(height: 8),
                                  _buildExpandableCategory("Programed"),
                                  const SizedBox(height: 8),
                                  _buildExpandableCategory("Last Vibe"),
                                ],
                              )
                            : SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      _buildGradientButton(
                        'Up Vibe',
                        () {
                          _controller.goToUpVibe(context, widget.user);
                        },
                        gradientColors: [Color(0xFF337DFF), Color(0xFFFF6E1F)],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildGradientButton('Log Out', () {
                  _controller.logout(context);
                }, gradientColors: [Colors.redAccent, Colors.red]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyInputDialog() {
    String _enteredKey = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar llave de acceso'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Pega la llave compartida aquí',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _enteredKey = value,
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Acceder'),
            onPressed: () async {
              Navigator.pop(context);
              await _accessWithKey(_enteredKey);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _accessWithKey(String publicKey) async {
    try {
      final query = await _firestore
          .collection('memories')
          .where('publicKey', isEqualTo: publicKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Llave no válida o recuerdo no encontrado');
      }

      final memory = query.docs.first.data();
      _viewMemory(memory);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _viewMemory(Map<String, dynamic> memory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recuerdo compartido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tipo: ${memory['type']}'),
            Text('Categoría: ${memory['category']}'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Ver contenido'),
              onPressed: () => _openMemoryContent(memory['downloadUrl']),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openMemoryContent(String downloadUrl) async {
    final url = Uri.parse(downloadUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir el contenido')));
    }
  }

  Widget _buildGradientButton(
    String text,
    VoidCallback onPressed, {
    required List<Color> gradientColors,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      splashColor: Colors.orangeAccent.withAlpha((0.3 * 255).toInt()),
      highlightColor: Colors.orangeAccent.withAlpha((0.15 * 255).toInt()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withAlpha((0.6 * 255).toInt()),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCategory(String label) {
    final isExpanded = expandedOptions[label] ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => toggleExpanded(label),
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildSubOptions(label),
        ],
      ),
    );
  }

  Widget _buildSubOptions(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      child: Column(
        children: [
          MediaOptionButton(
            iconData: Icons.mic,
            label: 'Audio',
            onPressed: () => _pickAndUploadFile('Audio', category),
          ),
          const SizedBox(height: 8),
          MediaOptionButton(
            iconData: Icons.videocam,
            label: 'Video',
            onPressed: () => _pickAndUploadFile('Video', category),
          ),
          const SizedBox(height: 8),
          MediaOptionButton(
            iconData: Icons.text_snippet,
            label: 'Texto',
            onPressed: () => _pickAndUploadFile('Texto', category),
          ),
          const SizedBox(height: 8),
          MediaOptionButton(
            iconData: Icons.photo,
            label: 'Foto',
            onPressed: () => _pickAndUploadFile('Foto', category),
          ),
        ],
      ),
    );
  }
}

class MediaOptionButton extends StatelessWidget {
  final IconData iconData;
  final String label;
  final VoidCallback onPressed;

  const MediaOptionButton({
    required this.iconData,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
