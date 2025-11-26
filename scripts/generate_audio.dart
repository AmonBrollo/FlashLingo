import 'dart:convert';
import 'dart:io';
import 'package:googleapis/texttospeech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flashlingo/models/flashcard.dart';

// CONFIGURATION
const String pathToServiceAccount = 'scripts/service_account.json';
const String outputDirectory = 'assets/audio';
const String dataDirectory = 'assets/data';

// If you want to process specific files only, list them here. Empty list = all JSONs.
const List<String> targetFiles = []; 

Future<void> main() async {
  print('🎙️  FlashLango Audio Generator Starting...');

  // 1. Authenticate with Google Cloud
  final serviceAccountFile = File(pathToServiceAccount);
  if (!serviceAccountFile.existsSync()) {
    print('❌ Error: Service account file not found at $pathToServiceAccount');
    print('   Please download your JSON key from GCP and place it there.');
    exit(1);
  }

  final accountCredentials = ServiceAccountCredentials.fromJson(
    serviceAccountFile.readAsStringSync(),
  );

  final scopes = [TexttospeechApi.cloudPlatformScope];
  final client = await clientViaServiceAccount(accountCredentials, scopes);
  final tts = TexttospeechApi(client);

  // 2. Setup Output Directory
  final outDir = Directory(outputDirectory);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 3. Process JSON Files
  final dataDir = Directory(dataDirectory);
  final jsonFiles = dataDir
      .listSync()
      .where((e) => 
          e.path.endsWith('.json') && 
          !e.path.contains('flashcards.json') &&
          !e.path.contains('topics.json')) // <-- ADDED THIS LINE
      .toList();

  print('📂 Found ${jsonFiles.length} topic files.');

  int totalGenerated = 0;
  int totalSkipped = 0;

  for (var fileEntity in jsonFiles) {
    final file = File(fileEntity.path);
    final fileName = file.uri.pathSegments.last;
    final topicName = fileName.replaceAll('.json', ''); // e.g. "adjectives"

    if (targetFiles.isNotEmpty && !targetFiles.contains(fileName)) continue;

    print('\n--- Processing Topic: $topicName ---');

    final content = file.readAsStringSync();
    final List<dynamic> data = jsonDecode(content);

    for (var item in data) {
      // Parse using your actual Flashcard model logic to ensure compatibility
      final card = Flashcard.fromJson(item);
      
      final englishText = card.getTranslation('english');
      final hungarianText = card.getTranslation('hungarian'); // Ensure case matches JSON

      if (hungarianText.isEmpty) {
        print('⚠️  Skipping "${englishText}": No Hungarian translation found.');
        continue;
      }

      // Use the SHARED logic to determine filename
      final audioFilename = Flashcard.getAudioFilename(topicName, englishText);
      final savePath = '$outputDirectory/$audioFilename';
      final saveFile = File(savePath);

      if (saveFile.existsSync()) {
        stdout.write('.'); // Dot indicates skipped/exists
        totalSkipped++;
        continue;
      }

      // Generate Audio
      try {
        await _generateAudio(tts, hungarianText, saveFile);
        stdout.write('✓'); // Check indicates success
        totalGenerated++;
      } catch (e) {
        print('\n❌ Error generating for "$englishText": $e');
      }
    }
  }

  print('\n\n✅ Complete!');
  print('   Generated: $totalGenerated');
  print('   Skipped (Already Existed): $totalSkipped');
  
  client.close();
}

Future<void> _generateAudio(
  TexttospeechApi tts,
  String text,
  File destination,
) async {
  final input = SynthesisInput(text: text);
  
  final voice = VoiceSelectionParams(
    languageCode: 'hu-HU',
    name: 'hu-HU-Wavenet-A', // Wavenet is higher quality, usually costs a tiny bit
    ssmlGender: 'FEMALE',
  );

  final audioConfig = AudioConfig(
    audioEncoding: 'MP3',
    speakingRate: 0.9, // Slightly slower for learning
  );

  final request = SynthesizeSpeechRequest(
    input: input,
    voice: voice,
    audioConfig: audioConfig,
  );

  final response = await tts.text.synthesize(request);

  if (response.audioContent != null) {
    // audioContent is Base64 encoded string
    final bytes = base64Decode(response.audioContent!);
    await destination.writeAsBytes(bytes);
  } else {
    throw Exception('API returned null audio content');
  }
}