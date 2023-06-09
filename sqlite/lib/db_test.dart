import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(MyApp());

int lastID = 0;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doggie Database',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Database database;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  List<Dog> dogList = [];

  @override
  void initState() {
    super.initState();
    initDB().then((db) {
      database = db;
      fetchDogs();
    });
  }

  Future<Database> initDB() async {
    return openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
  );
  }

  Future<void> insertDog(Dog dog) async {
    await database.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> fetchDogs() async {
    final List<Map<String, dynamic>> maps = await database.query('dogs');
    setState(() {
      dogList = List.generate(maps.length, (i) {
        return Dog(
          id: maps[i]['id'],
          name: maps[i]['name'],
          age: maps[i]['age'],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doggie Database'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final age = int.tryParse(ageController.text) ?? 0;
                final dog = Dog(id: lastID++, name: name, age: age);
                insertDog(dog).then((_) {
                  fetchDogs();
                  nameController.clear();
                  ageController.clear();
                });
              },
              child: Text('Add Dog'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dogList.length,
                itemBuilder: (context, index) {
                  final dog = dogList[index];
                  return ListTile(
                    title: Text(dog.name),
                    subtitle: Text('Age: ${dog.age}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Dog {
  final int id;
  final String name;
  final int age;

  const Dog({
    required this.id,
    required this.name,
    required this.age,
  });

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}