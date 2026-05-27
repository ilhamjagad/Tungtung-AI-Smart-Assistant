import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; // Untuk fitur Salin (Clipboard)
import 'package:share_plus/share_plus.dart'; // Untuk fitur Bagikan (Share)

void main() {
  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tungtung',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ChatScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF091636),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/logo.png', width: 80, height: 80),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tungtung',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smart AI Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: const Text(
                      'By Nodalixx.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  // --- VARIABEL MULTIMODAL ---
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _base64Image;

  List<Map<String, String>> _selectedFiles = [];

  List<Map<String, dynamic>> _allSessions = [];
  String? _currentSessionId;
  String _searchQuery = "";

  // Variabel Profil
  String _userName = "Ilham";
  String? _userProfileBase64;

  // Variabel Server API
  String _apiBaseUrl = 'http://10.0.2.2:8000';

  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadUserProfile();
    _loadAllSessions();
    _loadApiSettings();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        if (maxScroll - currentScroll > 50) {
          if (!_showScrollButton) setState(() => _showScrollButton = true);
        } else {
          if (_showScrollButton) setState(() => _showScrollButton = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // --- FUNGSI SALIN & BAGIKAN ---
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks disalin ke clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF2D2D2D),
      ),
    );
  }

  void _shareText(String text) {
    Share.share(text, subject: 'Pesan dari Tungtung AI');
  }

  // --- FUNGSI AMBIL GAMBAR ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // --- FUNGSI AMBIL DOKUMEN ---
  Future<void> _pickFolder() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'py', 'dart', 'json'],
    );

    if (result != null) {
      for (PlatformFile file in result.files) {
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          final base64Str = base64Encode(bytes);
          setState(() {
            _selectedFiles.add({'name': file.name, 'base64': base64Str});
          });
        }
      }
    }
  }

  // --- FUNGSI AMBIL FOTO DARI KAMERA ---
  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // --- FUNGSI MENU POP-UP ---
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2D2D2D),
                  child: Icon(Icons.image, color: Colors.blueAccent),
                ),
                title: const Text(
                  'Tambahkan Gambar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Pilih foto dari galeri',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2D2D2D),
                  child: Icon(Icons.camera_alt, color: Colors.greenAccent),
                ),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Gunakan kamera untuk mengambil foto',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2D2D2D),
                  child: Icon(Icons.description, color: Colors.orangeAccent),
                ),
                title: const Text(
                  'Tambahkan Dokumen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'PDF, Word, File Teks, atau Kodingan',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFolder();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIKA PROFIL PENGGUNA ---
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('jagad_ai_user_name') ?? "Ilham";
      _userProfileBase64 = prefs.getString('jagad_ai_user_profile');
    });
  }

  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jagad_ai_user_name', _userName);
    if (_userProfileBase64 != null) {
      await prefs.setString('jagad_ai_user_profile', _userProfileBase64!);
    } else {
      await prefs.remove('jagad_ai_user_profile');
    }
  }

  void _showProfileDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF091636),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white12, width: 1),
              ),
              title: const Text(
                'Edit Profil',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? pickedFile = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 60,
                      );
                      if (pickedFile != null) {
                        final bytes = await File(pickedFile.path).readAsBytes();
                        setDialogState(() {
                          _userProfileBase64 = base64Encode(bytes);
                        });
                        setState(() {});
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade700,
                      backgroundImage: _userProfileBase64 != null
                          ? MemoryImage(base64Decode(_userProfileBase64!))
                          : null,
                      child: _userProfileBase64 == null
                          ? Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ketuk foto untuk mengubah',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nama',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _userName = nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : "User";
                    });
                    _saveUserProfile();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIKA SETTING SERVER API ---
  Future<void> _loadApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiBaseUrl =
          prefs.getString('tungtung_api_base_url') ?? 'http://10.0.2.2:8000';
    });
  }

  Future<void> _saveApiSettings(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tungtung_api_base_url', newUrl);
    setState(() {
      _apiBaseUrl = newUrl;
    });
  }

  void _showApiSettingsDialog() {
    final TextEditingController urlController = TextEditingController(
      text: _apiBaseUrl,
    );
    String testStatus = "";
    Color testColor = Colors.white54;
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white12, width: 1),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dns_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pengaturan Server API',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesuaikan URL Backend untuk testing menggunakan Emulator atau Device fisik.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'URL Server Base',
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      hintText: 'http://10.0.2.2:8000',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: Colors.white54,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Preset Alamat:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text(
                          'Emulator (10.0.2.2)',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: const Color(0xFF2D2D2D),
                        labelStyle: const TextStyle(color: Colors.blueAccent),
                        onPressed: () {
                          setDialogState(() {
                            urlController.text = 'http://10.0.2.2:8000';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          'Localhost (127.0.0.1)',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: const Color(0xFF2D2D2D),
                        labelStyle: const TextStyle(color: Colors.orangeAccent),
                        onPressed: () {
                          setDialogState(() {
                            urlController.text = 'http://127.0.0.1:8000';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          'HP Fisik (Hotspot)',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: const Color(0xFF2D2D2D),
                        labelStyle: const TextStyle(color: Colors.greenAccent),
                        onPressed: () {
                          setDialogState(() {
                            urlController.text = 'http://172.20.10.3:8000';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isTesting
                            ? null
                            : () async {
                                setDialogState(() {
                                  isTesting = true;
                                  testStatus = "Menghubungkan...";
                                  testColor = Colors.white70;
                                });
                                try {
                                  final tempUrl = urlController.text.trim();
                                  await http
                                      .get(Uri.parse(tempUrl))
                                      .timeout(const Duration(seconds: 3));
                                  setDialogState(() {
                                    isTesting = false;
                                    testStatus = "Tersambung ke Server!";
                                    testColor = Colors.greenAccent;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isTesting = false;
                                    testStatus = "Koneksi Gagal / Timeout";
                                    testColor = Colors.redAccent;
                                  });
                                }
                              },
                        icon: isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blueAccent,
                                ),
                              )
                            : const Icon(
                                Icons.bolt,
                                size: 16,
                                color: Colors.blueAccent,
                              ),
                        label: const Text(
                          'Test Koneksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (testStatus.isNotEmpty)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              testStatus,
                              style: TextStyle(
                                color: testColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final cleanUrl = urlController.text.trim();
                    if (cleanUrl.isNotEmpty) {
                      _saveApiSettings(cleanUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Server disetel ke: $cleanUrl'),
                          backgroundColor: Colors.blueAccent,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIKA DATABASE LOKAL ---
  Future<void> _loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('jagad_ai_multi_sessions');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      setState(() {
        _allSessions = List<Map<String, dynamic>>.from(decodedData);
        if (_allSessions.isNotEmpty) _loadSession(_allSessions.first['id']);
      });
    }
  }

  Future<void> _saveAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jagad_ai_multi_sessions', jsonEncode(_allSessions));
  }

  void _loadSession(String sessionId) {
    final session = _allSessions.firstWhere(
      (s) => s['id'] == sessionId,
      orElse: () => {},
    );
    if (session.isNotEmpty) {
      setState(() {
        _currentSessionId = sessionId;
        _messages = List<Map<String, String>>.from(
          (session['messages'] as List).map(
            (item) => Map<String, String>.from(item),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _updateCurrentSession(String? firstMessage) {
    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      String title = firstMessage != null
          ? (firstMessage.length > 30
                ? '${firstMessage.substring(0, 30)}...'
                : firstMessage)
          : "Obrolan Baru";

      _allSessions.insert(0, {
        'id': _currentSessionId,
        'title': title,
        'messages': List<Map<String, String>>.from(_messages),
      });
    } else {
      final index = _allSessions.indexWhere(
        (s) => s['id'] == _currentSessionId,
      );
      if (index != -1) {
        _allSessions[index]['messages'] = List<Map<String, String>>.from(
          _messages,
        );
      }
    }
    _saveAllSessions();
  }

  void _deleteSession(String sessionId) {
    setState(() {
      _allSessions.removeWhere((s) => s['id'] == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
      }
    });
    _saveAllSessions();
  }

  void _showDeleteConfirmation(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Hapus Chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _deleteSession(sessionId);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
            if (_controller.text.trim().isNotEmpty ||
                _selectedImage != null ||
                _selectedFiles.isNotEmpty)
              _sendMessage();
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _controller.text = "";
        });
        _speech.listen(
          localeId: 'id_ID',
          onResult: (val) =>
              setState(() => _controller.text = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage({String? quickText}) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty && _selectedImage == null && _selectedFiles.isEmpty)
      return;

    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }

    String labelFile = "";
    if (_selectedFiles.isNotEmpty) {
      labelFile =
          "\n\n📂 *Melampirkan Dokumen:* " +
          _selectedFiles.map((f) => f['name']).join(', ');
    }

    final sentText = text.isEmpty
        ? "Tolong analisis file yang saya lampirkan."
        : text;
    final sentImageBase64 = _base64Image;
    final sentFilesList = List<Map<String, String>>.from(_selectedFiles);

    setState(() {
      _messages.add({
        "sender": "user",
        "text": "$sentText$labelFile",
        "image": sentImageBase64 ?? "",
      });
      _isLoading = true;
      _selectedImage = null;
      _base64Image = null;
      _selectedFiles.clear();
    });

    _updateCurrentSession(sentText);
    _controller.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    final url = Uri.parse('$_apiBaseUrl/api/chat');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pesan': sentText,
              'riwayat': _messages.map((m) {
                Map<String, dynamic> msgMap = {
                  'role': m['sender'] == 'user' ? 'user' : 'assistant',
                  'content': m['text'],
                };
                if (m['image'] != null && m['image']!.isNotEmpty) {
                  msgMap['images'] = [m['image']];
                }
                return msgMap;
              }).toList(),
              'files': sentFilesList
                  .map((f) => {'name': f['name'], 'base64': f['base64']})
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data.containsKey('reply')) {
            _messages.add({"sender": "ai", "text": data['reply'], "image": ""});
          } else {
            _messages.add({
              "sender": "ai",
              "text": "Maaf, terjadi kesalahan teknis.",
              "image": "",
            });
          }
        });
        _updateCurrentSession(null);
      }
    } catch (e) {
      setState(
        () => _messages.add({
          "sender": "ai",
          "text": "Error Asli: $e",
          "image": "",
        }),
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildLandingPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/logo.png', width: 56, height: 56),
          ),
          const SizedBox(height: 24),
          Text(
            'Halo! $_userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ada yang bisa saya bantu?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFFC4C7C5),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tungtung',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _showProfileDialog,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black,
                  backgroundImage: _userProfileBase64 != null
                      ? MemoryImage(base64Decode(_userProfileBase64!))
                      : null,
                  child: _userProfileBase64 == null
                      ? Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282A2D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white54, size: 20),
                      hintText: "Telusuri percakapan",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
                leading: const Icon(
                  Icons.edit_square,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Chat baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentSessionId = null;
                    _messages.clear();
                    _selectedImage = null;
                    _selectedFiles.clear();
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  "Percakapan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredSessions = _searchQuery.isEmpty
                        ? _allSessions
                        : _allSessions
                              .where(
                                (s) => s['title']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final s = filteredSessions[index];
                        final isSelected = _currentSessionId == s['id'];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                          ),
                          title: Text(
                            s['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.push_pin_outlined,
                                  color: Colors.white54,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            _loadSession(s['id']);
                            Navigator.pop(context);
                          },
                          onLongPress: () => _showDeleteConfirmation(s['id']),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 4.0,
                ),
                leading: const Icon(
                  Icons.dns_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Pengaturan Server',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showApiSettingsDialog();
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF091636),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _messages.isEmpty
                        ? _buildLandingPage()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isUser = msg["sender"] == "user";
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: isUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          left: isUser ? 48.0 : 0,
                                          right: 0,
                                        ),
                                        padding: EdgeInsets.all(
                                          isUser ? 14 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                            color: isUser
                                                ? const Color(0xFF2D2D2D)
                                                : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (msg.containsKey('image') &&
                                                msg['image']!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.memory(
                                                    base64Decode(msg['image']!),
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.6,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),

                                            MarkdownBody(
                                              data: msg["text"]!,
                                              selectable: true,
                                              styleSheet: MarkdownStyleSheet(
                                                p: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFFE3E3E3),
                                                  height: 1.5,
                                                ),
                                                code: const TextStyle(
                                                  backgroundColor: Color(
                                                    0xFF1E1E1E,
                                                  ),
                                                  color: Colors.lightBlueAccent,
                                                ),
                                              ),
                                            ),

                                            // --- TOMBOL SALIN & BAGIKAN KHUSUS BALASAN AI ---
                                            if (!isUser)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12.0,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () =>
                                                          _copyToClipboard(
                                                            msg["text"]!,
                                                          ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 4.0,
                                                              horizontal: 8.0,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.copy,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              "Salin",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    InkWell(
                                                      onTap: () => _shareText(
                                                        msg["text"]!,
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 4.0,
                                                              horizontal: 8.0,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.share,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              "Bagikan",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  if (_showScrollButton && _messages.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          mini: true,
                          shape: const CircleBorder(),
                          backgroundColor: const Color(0xFF2D2D2D),
                          onPressed: _scrollToBottom,
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Colors.blueAccent,
                minHeight: 2,
              ),

            // --- KOTAK PREVIEW GAMBAR ---
            if (_selectedImage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 16, bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: -10,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setState(() {
                          _selectedImage = null;
                          _base64Image = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),

            // --- KOTAK PREVIEW CHIP FILE ---
            if (_selectedFiles.isNotEmpty)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orangeAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            file['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFiles.removeAt(index)),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D21),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF2E3238),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white70,
                          size: 24,
                        ),
                        onPressed: _showAttachmentOptions,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tanya Tungtung...',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _listen,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.white54,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade700,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
