import 'package:flutter/material.dart';
import 'db_test.dart';
import 'keyValue.dart';
import 'readWrite.dart';

void main() => runApp(MyApp());

enum SelectedOption {
  SQLite,
  Files,
  KeyValue,
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SelectedOption _selectedOption = SelectedOption.SQLite;

  Widget _buildSelectedOptionWidget() {
    switch (_selectedOption) {
      case SelectedOption.SQLite:
        return SQLite();
      case SelectedOption.Files:
        return KeyValue();
      case SelectedOption.KeyValue:
        return ReadWrite();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Selection',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Button Selection'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildSelectedOptionWidget(),
            ),
            Container(
              color: Colors.blue,
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = SelectedOption.SQLite;
                      });
                    },
                    child: Text('SQLite'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = SelectedOption.Files;
                      });
                    },
                    child: Text('Key-Value'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedOption = SelectedOption.KeyValue;
                      });
                    },
                    child: Text('Files'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
