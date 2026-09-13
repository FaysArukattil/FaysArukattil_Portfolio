import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_portfolio/services/resumegeneration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate resume pdf produces exactly 2 pages', () async {
    final service = ResumeGeneratorService();
    final bytes = await service.generateResumePDF([]);
    final file = File('build/test_resume.pdf');
    await file.writeAsBytes(bytes);

    final text = String.fromCharCodes(bytes);
    final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(text);
    expect(pageMatches.length, equals(2),
        reason: 'Resume PDF must fit on exactly 2 pages');
  });
}
