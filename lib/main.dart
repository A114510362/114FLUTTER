import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicPlayerMainPage(),
    );
  }
}

class MusicPlayerMainPage extends StatefulWidget {
  const MusicPlayerMainPage({super.key});

  @override
  State<MusicPlayerMainPage> createState() => _MusicPlayerMainPageState();
}

class SongItem {
  String title;
  String artist;
  final String videoPath;
  SongItem({required this.title, required this.artist, required this.videoPath});
}

class _MusicPlayerMainPageState extends State<MusicPlayerMainPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = true; // 預設靜音（僅在第一次開啟時生效）

  final List<SongItem> _playList = [];
  final int _totalSongsCount = 5;

  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool _isEditingTitle = false;
  bool _isEditingArtist = false;
  late TextEditingController _titleController;
  late TextEditingController _artistController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _artistController = TextEditingController();

    for (int i = 1; i <= _totalSongsCount; i++) {
      _playList.add(
        SongItem(
          title: "第 $i 首未命名歌曲",
          artist: "未知歌手",
          videoPath: "assets/videos/$i.mp4",
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_playList.isNotEmpty) {
        _initVideo(_playList[_currentIndex].videoPath);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    setState(() {
      _currentPosition = _videoController!.value.position;
    });
  }

  Future<void> _initVideo(String path) async {
    setState(() {
      _isVideoInitialized = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });

    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.dispose();
    }

    _videoController = VideoPlayerController.asset(path);

    try {
      await _videoController!.initialize();
      // 關鍵改動：根據當前 _isMuted 狀態設定音量，而不是強制為靜音
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      _videoController!.setLooping(true);
      await _videoController!.play();
      
      _totalDuration = _videoController!.value.duration;
      _videoController!.addListener(_videoListener);
      
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (e) {
      debugPrint("影片初始化失敗: $e");
    }
  }

  void _changeSong(int index) async {
    int newIndex = index % _playList.length;
    if (newIndex < 0) newIndex += _playList.length;

    setState(() {
      _currentIndex = newIndex;
      _titleController.text = _playList[_currentIndex].title;
      _artistController.text = _playList[_currentIndex].artist;
    });
    await _initVideo(_playList[_currentIndex].videoPath);
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double sliderValue = 0.0;
    if (_totalDuration.inMilliseconds > 0) {
      sliderValue = (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _isVideoInitialized && _videoController != null
                              ? VideoPlayer(_videoController!)
                              : const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                        Positioned.fill(
                          child: Container(color: Colors.black.withOpacity(0.25)),
                        ),
                        // 右上角聲音按鈕 (往下調)
                        Positioned(
                          top: 40,
                          right: 10,
                          child: IconButton(
                            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 28),
                            onPressed: _toggleMute,
                          ),
                        ),
                        Positioned(
                          bottom: 30, left: 16, right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isEditingTitle
                                  ? TextField(
                                      controller: _titleController,
                                      autofocus: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(border: InputBorder.none),
                                      onSubmitted: (value) {
                                        setState(() {
                                          _playList[_currentIndex].title = value.isEmpty ? "未命名歌曲" : value;
                                          _isEditingTitle = false;
                                        });
                                      },
                                    )
                                  : GestureDetector(
                                      onTap: () => setState(() => _isEditingTitle = true),
                                      child: Text(_playList[_currentIndex].title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                    ),
                              const SizedBox(height: 4),
                              _isEditingArtist
                                  ? TextField(
                                      controller: _artistController,
                                      autofocus: true,
                                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(border: InputBorder.none),
                                      onSubmitted: (value) {
                                        setState(() {
                                          _playList[_currentIndex].artist = value.isEmpty ? "未知歌手" : value;
                                          _isEditingArtist = false;
                                        });
                                      },
                                    )
                                  : GestureDetector(
                                      onTap: () => setState(() => _isEditingArtist = true),
                                      child: Text(_playList[_currentIndex].artist, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                                    ),
                              const SizedBox(height: 20),
                              Slider(
                                value: sliderValue,
                                onChanged: (value) {
                                  if (_videoController != null && _isVideoInitialized) {
                                    final target = (_totalDuration.inMilliseconds * value).toInt();
                                    _videoController!.seekTo(Duration(milliseconds: target));
                                  }
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () => _changeSong(_currentIndex - 1)),
                                  Container(
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), 
                                    child: IconButton(
                                      icon: Icon(_videoController?.value.isPlaying == true ? Icons.pause : Icons.play_arrow, color: Colors.black), 
                                      onPressed: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play())
                                    )
                                  ),
                                  IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () => _changeSong(_currentIndex + 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(color: Colors.black, padding: const EdgeInsets.all(20), child: Text("共 ${_playList.length} 部影片", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Container(
                    color: Colors.white,
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _playList.length,
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _playList.removeAt(oldIndex);
                          _playList.insert(newIndex, item);
                          if (oldIndex == _currentIndex) _currentIndex = newIndex;
                        });
                      },
                      itemBuilder: (context, index) {
                        final song = _playList[index];
                        return ListTile(
                          key: ValueKey(song.videoPath),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: const Icon(Icons.drag_handle),
                          onTap: () => _changeSong(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}