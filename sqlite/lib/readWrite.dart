import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ReadWrite extends StatelessWidget {
  ReadWrite({Key? key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Read Write demo',
      home: FlutterDemo(title: 'Read Write demo', storage: FileStorage()),
    );
  }
}

class FileStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/my_file.txt');
  }

  Future<String> readFile() async {
    try {
      final file = await _localFile;
      return await file.readAsString();
    } catch (e) {
      return '';
    }
  }

  Future<File> writeFile(String content) async {
    final file = await _localFile;
    return file.writeAsString(content);
  }

  Future<String?> openFile() async {
    try {
      final file = await _localFile;
      final exists = await file.exists();
      if (exists) {
        return file.path;
      }
    } catch (e) {
      print('Error opening file: $e');
    }
    return null;
  }
}

class FlutterDemo extends StatefulWidget {
  FlutterDemo({Key? key, required this.title, required this.storage});

  final FileStorage storage;
  final String title;

  @override
  State<FlutterDemo> createState() => _FlutterDemoState();
}

class _FlutterDemoState extends State<FlutterDemo> {
  final TextEditingController _textEditingController = TextEditingController();
  late Future<String> _fileContentFuture;

  @override
  void initState() {
    super.initState();
    _fileContentFuture = widget.storage.readFile();
  }

  Future<void> _saveFile() async {
    final content = _textEditingController.text;
    await widget.storage.writeFile(content);
    _textEditingController.clear();
    setState(() {
      _fileContentFuture = Future.value('');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved successfully!')),
    );
  }

  Future<void> _openFile() async {
    final filePath = await widget.storage.openFile();
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File opened successfully!')),
      );
      setState(() {
        _fileContentFuture = Future.value(File(filePath).readAsStringSync());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File does not exist!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading and Writing Files'),
      ),
      body: FutureBuilder<String>(
        future: _fileContentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final fileContent = snapshot.data ?? '';
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _textEditingController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Enter text',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _saveFile,
                        child: const Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: _openFile,
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  if (fileContent.isNotEmpty) Text(fileContent),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
