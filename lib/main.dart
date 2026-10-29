import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const LosslessMusicApp());
}

class LosslessMusicApp extends StatelessWidget {
  const LosslessMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hi-Res Lossless Player',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFA243C), // Apple Music Red/Pink
      ),
      home: const MusicHomeScreen(),
    );
  }
}

class Song {
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final String qualityBadge; // e.g., "FLAC 24-bit/96kHz"

  Song({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.qualityBadge,
  });
}

class MusicHomeScreen extends StatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;
  bool _isPlaying = false;

  // Sample Royalty-Free Lossless / High-Quality Tracks
  final List<Song> _playlist = [
    Song(
      title: " Clair de Lune (Lossless Master)",
      artist: "Claude Debussy",
      coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600",
      // Sample FLAC stream URL
      audioUrl: "https://filesamples.com/samples/audio/flac/sample3.flac",
      qualityBadge: "LOSSLESS • 24-bit/96kHz FLAC",
    ),
    Song(
      title: "Midnight Synthwave",
      artist: "Indie Studio",
      coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600",
      audioUrl: "https://filesamples.com/samples/audio/flac/sample4.flac",
      qualityBadge: "LOSSLESS • 16-bit/44.1kHz FLAC",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSong(_currentIndex);
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  Future<void> _loadSong(int index) async {
    try {
      await _audioPlayer.setUrl(_playlist[index].audioUrl);
    } catch (e) {
      debugPrint("Error loading lossless audio: $e");
    }
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _nextSong() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    });
    _loadSong(_currentIndex);
    _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _playlist[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Listen Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album Art with Shadow
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
                image: DecorationImage(
                  image: NetworkImage(currentSong.coverUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Song Title & Artist
            Text(
              currentSong.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentSong.artist,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Apple Music Style "Lossless" Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq, size: 14, color: Colors.amberAccent),
                  const SizedBox(width: 6),
                  Text(
                    currentSong.qualityBadge,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      activeColor: const Color(0xFFFA243C),
                      inactiveColor: Colors.white24,
                      value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
                      max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            ),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: _nextSong,
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _playPause,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFFA243C),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: _nextSong,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
