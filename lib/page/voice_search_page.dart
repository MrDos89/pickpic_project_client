import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pickpic_project_client/components/GalleryImageGrid.dart';

class VoiceSearchPage extends StatefulWidget {
  final stt.SpeechToText? injectedSpeech;

  const VoiceSearchPage({Key? key, this.injectedSpeech}) : super(key: key);

  @override
  _VoiceSearchPageState createState() => _VoiceSearchPageState();
}

class _VoiceSearchPageState extends State<VoiceSearchPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  DateTime? _lastSpokenTime;
  final Duration _silenceThreshold = Duration(seconds: 2);
  late final Ticker _ticker;

  final ScrollController _scrollController = ScrollController();
  List<String> images = List.generate(20, (index) => '사진 $index');
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = widget.injectedSpeech ?? stt.SpeechToText();
    _ticker = Ticker(_checkSilence)..start();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _lastSpokenTime = DateTime.now();
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              _lastSpokenTime = DateTime.now();
            });
          },
        );
      }
    } else {
      _stopListeningAndSearch();
    }
  }

  void _checkSilence(Duration elapsed) {
    if (_isListening && _lastSpokenTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastSpokenTime!) > _silenceThreshold) {
        _stopListeningAndSearch();
      }
    }
  }

  void _stopListeningAndSearch() {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      debugPrint('검색 실행: $_text');
      // TODO: 검색 로직과 연동 가능
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !isLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      images.addAll(List.generate(20, (index) => '사진 ${images.length + index}'));
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: ElevatedButton(
            onPressed: _listen,
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(40),
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(_text, style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        Expanded(
          // child: GridView.builder(
          //   controller: _scrollController,
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          //   itemCount: images.length + (isLoading ? 1 : 0),
          //   itemBuilder: (context, index) {
          //     if (index >= images.length) {
          //       return Center(child: CircularProgressIndicator());
          //     }
          //     return Card(child: Center(child: Text(images[index])));
          //   },
          // ),
          child: GalleryImageGrid(),
        ),
      ],
    );
  }
}
