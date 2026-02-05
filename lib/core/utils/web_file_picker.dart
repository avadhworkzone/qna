import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'web_file_picker_result.dart';

class WebFilePicker {
  static Future<CsvPickResult?> pickCsvData() async {
    final completer = Completer<CsvPickResult?>();
    final input = html.FileUploadInputElement();
    input.accept = '.csv,text/csv';
    input.value = '';
    input.style.display = 'none';
    html.document.body?.append(input);
    input.onChange.first.then((_) {
      final file = input.files?.first;
      if (file == null) {
        input.remove();
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoad.first.then((_) {
        input.remove();
        final result = reader.result;
        String? text;
        if (result is String) {
          text = result;
        } else if (result is ByteBuffer) {
          text = utf8.decode(result.asUint8List());
        } else if (result is Uint8List) {
          text = utf8.decode(result);
        } else if (result is List<int>) {
          text = utf8.decode(result);
        }
        if (text == null) {
          completer.complete(null);
          return;
        }
        completer.complete(CsvPickResult(name: file.name, text: text));
      });
      reader.onError.first.then((_) {
        input.remove();
        completer.complete(null);
      });
      reader.readAsText(file);
    });
    input.onError.first.then((_) {
      input.remove();
      completer.complete(null);
    });
    input.click();
    return completer.future;
  }

  static Future<String?> pickCsvText() async {
    final result = await pickCsvData();
    return result?.text;
  }
}
