import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  @override
  void initState() {
    super.initState();
    _speech = widget.injectedSpeech ?? stt.SpeechToText();
    _ticker = Ticker(_checkSilence)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
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
      debugPrint('검색 실행: \$_text');
      // TODO: 여기에 실제 검색 함수 연동 가능
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
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
          SizedBox(height: 20),
          Text(_text, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
