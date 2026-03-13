import 'dart:io';

/// Renames Hungarian audio files from `topic_word.mp3` to `topic_word_hu.mp3`
/// 
/// This script identifies files that don't have a language suffix (_en, _es, _hu)
/// and adds the _hu suffix to them.

const String audioDirectory = 'assets/audio';

Future<void> main() async {
  print('🔄 Hungarian Audio File Renamer\n');
  
  final dir = Directory(audioDirectory);
  
  if (!dir.existsSync()) {
    print('❌ Error: Directory $audioDirectory does not exist');
    exit(1);
  }

  // Get all .mp3 files
  final files = dir
      .listSync()
      .where((e) => e.path.endsWith('.mp3'))
      .map((e) => File(e.path))
      .toList();

  print('📂 Found ${files.length} total audio files\n');

  int renamed = 0;
  int skipped = 0;
  
  for (var file in files) {
    final fileName = file.uri.pathSegments.last;
    
    // Check if file already has a language suffix
    if (fileName.endsWith('_en.mp3') || 
        fileName.endsWith('_es.mp3') || 
        fileName.endsWith('_hu.mp3')) {
      skipped++;
      continue;
    }
    
    // This is a Hungarian file without suffix - rename it
    final newFileName = fileName.replaceAll('.mp3', '_hu.mp3');
    final newPath = '${dir.path}/$newFileName';
    
    try {
      await file.rename(newPath);
      print('✓ Renamed: $fileName → $newFileName');
      renamed++;
    } catch (e) {
      print('✗ Failed to rename $fileName: $e');
    }
  }
  
  print('\n✅ Complete!');
  print('   Renamed: $renamed files');
  print('   Skipped (already have suffix): $skipped files');
  print('\nAll Hungarian audio files now have the _hu suffix!');
}