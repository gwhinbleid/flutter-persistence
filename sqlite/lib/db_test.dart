import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

int lastID = 0;

class SQLite extends StatelessWidget {
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
      setState(() {
        database = db;
        fetchDogs();
      });
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


  Future<void> deleteDog(int id) async {
    final db = await database;
    await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
    //fetchDogs(); // Fetch the updated list after deleting the dog
  }

  Future<List<Dog>> fetchDogs() async {
    final List<Map<String, dynamic>> maps = await database.query('dogs');
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });
  }

  Future<void> updateDog(Dog dog) async {
    final db = await database;
    await db.update(
      'dogs',
      dog.toMap(),
      where: 'id = ?',
      whereArgs: [dog.id],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Dog Name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: ageController,
              decoration: InputDecoration(
                labelText: 'Dog Age',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final age = int.tryParse(ageController.text) ?? 0;
              final dog = Dog(id: lastID++, name: name, age: age);
              insertDog(dog).then((_) {
                setState(() {
                  nameController.clear();
                  ageController.clear();
                });
              });
            },
            child: Text('Add Dog'),
          ),
          FutureBuilder<List<Dog>>(
            future: fetchDogs(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final dogList = snapshot.data!;
                return Expanded(
                  child: ListView.builder(
                    itemCount: dogList.length,
                    itemBuilder: (context, index) {
                      final dog = dogList[index];
                      return ListTile(
                        title: Text(dog.name),
                        subtitle: Text('Age: ${dog.age}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                deleteDog(dog.id).then((_) {
                                  setState(() {
                                    fetchDogs();
                                  });
                                });
                              },
                              child: Icon(Icons.delete),
                            ),
                            SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final updatedNameController = TextEditingController(text: dog.name);
                                    final updatedAgeController = TextEditingController(text: dog.age.toString());
                                    return AlertDialog(
                                      title: Text('Update Dog'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: updatedNameController,
                                            decoration: InputDecoration(
                                              labelText: 'Dog Name',
                                            ),
                                          ),
                                          TextField(
                                            controller: updatedAgeController,
                                            decoration: InputDecoration(
                                              labelText: 'Dog Age',
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final updatedName = updatedNameController.text;
                                            final updatedAge = int.tryParse(updatedAgeController.text) ?? 0;
                                            final updatedDog = Dog(
                                              id: dog.id,
                                              name: updatedName,
                                              age: updatedAge,
                                            );
                                            updateDog(updatedDog).then((_) {
                                              setState(() {
                                                fetchDogs();
                                              });
                                              Navigator.of(context).pop();
                                            });
                                          },
                                          child: Text('Update'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Icon(Icons.edit),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ],
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