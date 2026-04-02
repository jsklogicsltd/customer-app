import 'dart:io';

void main() async {
  print('Starting analyzer...');
  final result = await Process.run('flutter', ['analyze', '--machine']);
  File('analyze_results.txt').writeAsStringSync('STDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}');
  print('Done.');
}
