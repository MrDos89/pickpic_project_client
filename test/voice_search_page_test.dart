import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpic_project_client/page/voice_search_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'voice_search_page_test.mocks.dart';

@GenerateMocks([stt.SpeechToText])
void main() {
  late MockSpeechToText mockSpeechToText;

  setUp(() {
    mockSpeechToText = MockSpeechToText();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: VoiceSearchPageWithMock(speechToText: mockSpeechToText),
      ),
    );
  }

  testWidgets('initial UI renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.text(''), findsOneWidget);
  });

  testWidgets('tapping mic triggers speech recognition', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
    when(mockSpeechToText.isAvailable).thenReturn(true);
    when(mockSpeechToText.listen(onResult: anyNamed('onResult'))).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(mockSpeechToText.initialize()).called(1);
    verify(mockSpeechToText.listen(onResult: anyNamed('onResult'))).called(1);
  });
}

class VoiceSearchPageWithMock extends StatefulWidget {
  final stt.SpeechToText speechToText;

  const VoiceSearchPageWithMock({Key? key, required this.speechToText}) : super(key: key);

  @override
  _VoiceSearchPageWithMockState createState() => _VoiceSearchPageWithMockState();
}

class _VoiceSearchPageWithMockState extends State<VoiceSearchPageWithMock> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = widget.speechToText;
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _text = result.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
