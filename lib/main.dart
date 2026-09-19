import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const ABacaApp());
}

class ABacaApp extends StatelessWidget {
  const ABacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A-BACA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Warm Cream
        primaryColor: const Color(0xFF8B4513), // Saddle Brown / Cokelat Tua
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD2691E),
          secondary: const Color(0xFFE05D36), // Vibrant Terracotta
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Engine Suara
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  
  bool _isListening = false;
  String _recognizedText = "";
  String _mascotSpeech = "Halo teman-teman! Yuk kita belajar membaca bersama!";
  
  // Data Modul Pembelajaran
  int _currentLevelIndex = 0;
  final List<Map<String, String>> _levels = [
    {"target": "BA", "hint": "B dan A dibaca BA"},
    {"target": "BUKU", "hint": "B-U BU, K-U KU... BUKU"},
    {"target": "SATE", "hint": "S-A SA, T-E TE... SATE"},
    {"target": "BATIK", "hint": "B-A BA, T-I-K TIK... BATIK"},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  // Inisialisasi Text-To-Speech Bahasa Indonesia
  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setPitch(1.2); // Pitch agak tinggi agar terdengar ceria
    await _flutterTts.setSpeechRate(0.4); // Kecepatan lambat ramah anak
    _speak(_mascotSpeech);
  }

  // Inisialisasi AI Speech Recognition
  void _initSpeech() async {
    _speech = stt.SpeechToText();
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Logika AI Mendengarkan dan Evaluasi Suara Anak
  void _listenAndEvaluate() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = "";
          _mascotSpeech = "Aku sedang mendengarkan... Katakan '${_levels[_currentLevelIndex]['target']}'!";
        });
        
        _speech.listen(
          localeId: "id_ID",
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords.toUpperCase();
              _evaluateSpeech(_recognizedText);
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Algoritma Evaluasi AI (Toleran untuk Artikulasi Anak)
  void _evaluateSpeech(String input) {
    String target = _levels[_currentLevelIndex]['target']!;
    
    // Fuzzy Matching Sederhana / Pencocokan Fonetik
    if (input.contains(target) || _isFuzzyMatch(input, target)) {
      setState(() {
        _mascotSpeech = "Hebat sekali! Pengucapanmu tepat!";
      });
      _speak("Hebat sekali! Jawabanmu benar!");
      
      // Lanjut ke level berikutnya setelah jeda
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentLevelIndex < _levels.length - 1) {
          setState(() {
            _currentLevelIndex++;
            _recognizedText = "";
            _mascotSpeech = "Sekarang, coba baca kata ini!";
          });
          _speak(_mascotSpeech);
        }
      });
    } else if (input.isNotEmpty) {
      setState(() {
        _mascotSpeech = "Hampir pas! Coba ikuti suaraku ya...";
      });
      _speak("Hampir betul! Dengarkan suara maskot ya: $target");
    }
  }

  bool _isFuzzyMatch(String input, String target) {
    // Memaklumi kesalahan pelafalan minor anak (misal: "PATU" untuk "SEPATU")
    if (input.length < 2) return false;
    return target.endsWith(input) || input.endsWith(target);
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk penyesuaian responsif
    final screenSize = MediaQuery.of(context).size;
    final isTabletOrBoard = screenSize.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTabletOrBoard ? 32.0 : 16.0),
          child: Column(
            children: [
              // 1. Header & Maskot
              _buildMascotHeader(isTabletOrBoard),
              const SizedBox(height: 20),

              // 2. Area Kartu Pembelajaran Utama (Card UI Cokelat Krem)
              Expanded(
                child: _buildLearningCard(isTabletOrBoard),
              ),

              const SizedBox(height: 20),

              // 3. Tombol Interaksi (Bicara / Rekam AI)
              _buildControlButtons(isTabletOrBoard),
            ],
          ),
        ),
      ),
    );
  }

  // Komponen Maskot
  Widget _buildMascotHeader(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC), // Cornsilk Krem
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD2691E), width: 2),
      ),
      child: Row(
        children: [
          // Avatar Maskot Anak
          CircleAvatar(
            radius: isLargeScreen ? 45 : 30,
            backgroundColor: const Color(0xFFE05D36),
            child: Text(
              "👦🏽",
              style: TextStyle(fontSize: isLargeScreen ? 40 : 28),
            ),
          ),
          const SizedBox(width: 16),
          // Balon Bicara Maskot
          Expanded(
            child: Text(
              _mascotSpeech,
              style: TextStyle(
                fontSize: isLargeScreen ? 20 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B2818),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Color(0xFF8B4513)),
            iconSize: isLargeScreen ? 36 : 28,
            onPressed: () => _speak(_mascotSpeech),
          )
        ],
      ),
    );
  }

  // Komponen Kartu Baca Suku Kata / Kata
  Widget _buildLearningCard(bool isLargeScreen) {
    String currentTarget = _levels[_currentLevelIndex]['target']!;
    String currentHint = _levels[_currentLevelIndex]['hint']!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B2818).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF5DEB3), width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Tingkat ${_currentLevelIndex + 1} dari ${_levels.length}",
            style: const TextStyle(
              color: Color(0xFFD2691E),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Teks Target Utama (Sangat Besar & Jelas)
          Text(
            currentTarget,
            style: TextStyle(
              fontSize: isLargeScreen ? 96 : 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              color: const Color(0xFF3B2818),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentHint,
            style: TextStyle(
              fontSize: isLargeScreen ? 22 : 16,
              color: const Color(0xFF8B4513).withOpacity(0.8),
            ),
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Suara kamu: $_recognizedText",
                style: const TextStyle(
                  color: Color(0xFFE05D36),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Tombol Aksi Utama
  Widget _buildControlButtons(bool isLargeScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol Contoh Suara
        ElevatedButton.icon(
          onPressed: () => _speak(_levels[_currentLevelIndex]['target']!),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text("Dengarkan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD2691E),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 32 : 20,
              vertical: isLargeScreen ? 20 : 14,
            ),
            textStyle: TextStyle(
              fontSize: isLargeScreen ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Tombol Mikrofon AI (Besar & Interaktif)
        GestureDetector(
          onTap: _listenAndEvaluate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isLargeScreen ? 28 : 20),
            decoration: BoxDecoration(
              color: _isListening ? const Color(0xFFE05D36) : const Color(0xFF8B4513),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? const Color(0xFFE05D36) : const Color(0xFF8B4513)).withOpacity(0.4),
                  blurRadius: _isListening ? 25 : 10,
                  spreadRadius: _isListening ? 8 : 2,
                )
              ],
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: isLargeScreen ? 48 : 36,
            ),
          ),
        ),
      ],
    );
  }
}
