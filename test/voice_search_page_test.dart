import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickpic_project_client/page/voice_search_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

import 'voice_search_page_test.mocks.dart';

@GenerateMocks([stt.SpeechToText, stt.SpeechRecognitionResult])
void main() {
  late MockSpeechToText mockSpeechToText;

  setUp(() {
    mockSpeechToText = MockSpeechToText();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: VoiceSearchPage(injectedSpeech: mockSpeechToText),
      ),
    );
  }

  testWidgets('initial UI renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.text(''), findsOneWidget);
  });

  testWidgets('tapping mic triggers speech recognition and stops after silence', (WidgetTester tester) async {
    when(mockSpeechToText.initialize()).thenAnswer((_) async => true);

    final mockResult = MockSpeechRecognitionResult();
    when(mockResult.recognizedWords).thenReturn('테스트 음성');
    when(mockResult.finalResult).thenReturn(true);

    when(mockSpeechToText.listen(onResult: anyNamed('onResult'))).thenAnswer((invocation) {
      final callback = invocation.namedArguments[#onResult] as void Function(stt.SpeechRecognitionResult);
      Future.delayed(Duration(milliseconds: 500), () {
        callback(mockResult);
      });
      return Future.value();
    });

    when(mockSpeechToText.stop()).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    await tester.pump(Duration(seconds: 3));

    verify(mockSpeechToText.stop()).called(1);
    expect(find.text('테스트 음성'), findsOneWidget);
  });
}
