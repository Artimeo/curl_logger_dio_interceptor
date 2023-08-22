import 'dart:developer' as developer;

import 'package:logger/logger.dart';

class DeveloperLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    developer.log('cURL representation\n${event.lines.join('\n')}', name: 'dio curl');
  }
}
