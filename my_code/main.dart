import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const LosslessMusicApp());

class LosslessMusicApp extends StatelessWidget {
  const LosslessMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MusicPlayerScreen(),
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String streamUrl; // FLAC या ALAC फाइल का URL

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.streamUrl,
  });
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localFilePath;

  // सैंपल Lossless FLAC ट्रैक
  final Song currentSong = Song(
    id: "track_01",
    title: "Sample Lossless Track (24-bit/96kHz)",
    artist: "Hi-Res Artist",
    streamUrl: "https://filesamples.com/samples/audio/flac/sample3.flac",
  );

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  // चेक करें कि गाना पहले से ऑफलाइन मौजूद है या नहीं
  Future<void> _checkIfDownloaded() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${currentSong.id}.flac');
    if (await file.exists()) {
      setState(() {
        _localFilePath = file.path;
      });
    }
  }

  // गाना प्ले करें (अगर ऑफलाइन है तो लोकल से, वरना ऑनलाइन स्ट्रीम करें)
  Future<void> _playMusic() async {
    try {
      if (_localFilePath != null) {
        // ऑफलाइन प्लेबैक
        await _player.setFilePath(_localFilePath!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playing Offline (Lossless)')),
        );
      } else {
        // ऑनलाइन स्ट्रीमिंग
        await _player.setUrl(currentSong.streamUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Streaming Online (Lossless)')),
        );
      }
      _player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  // गाने को ऑफलाइन सुनने के लिए डाउनलोड करें
  Future<void> _downloadLosslessTrack() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${currentSong.id}.flac';

      await _dio.download(
        currentSong.streamUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _localFilePath = savePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download Complete! Ready for offline play.')),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download Failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hi-Res Lossless Player")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // एल्बम आर्ट प्लेसहोल्डर
            Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
            ),
            const SizedBox(height: 20),

            // Lossless बैज (Apple Music स्टाइल)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "LOSSLESS • 24-bit/96kHz FLAC",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // गाने का नाम और आर्टिस्ट
            Text(currentSong.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(currentSong.artist, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),

            // प्ले / पॉज़ और डाउनलोड कंट्रोल्स
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      iconSize: 64,
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      onPressed: () {
                        if (playing) {
                          _player.pause();
                        } else {
                          _playMusic();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 24),
                if (_isDownloading)
                  CircularProgressIndicator(value: _downloadProgress)
                else if (_localFilePath != null)
                  const Icon(Icons.download_done, color: Colors.green, size: 36)
                else
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    onPressed: _downloadLosslessTrack,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _localFilePath != null ? "Status: Offline Available" : "Status: Online Stream Only",
              style: TextStyle(color: _localFilePath != null ? Colors.greenAccent : Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
