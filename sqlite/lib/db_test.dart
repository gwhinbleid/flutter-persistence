import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

int lastID = 0;

class SQLite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Database',
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
  final TextEditingController titleController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  List<Anime> animeList = [];

  @override
  void initState() {
    super.initState();
    initDB().then((db) {
      setState(() {
        database = db;
        fetchAnimes();
      });
    });
  }

  Future<Database> initDB() async {
    return openDatabase(
      join(await getDatabasesPath(), 'anime_database.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE animes(id INTEGER PRIMARY KEY, title TEXT, rating INTEGER)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<void> insertAnime(Anime anime) async {
    await database.insert(
      'animes',
      anime.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<void> deleteAnime(int id) async {
    final db = await database;
    await db.delete(
      'animes',
      where: 'id = ?',
      whereArgs: [id],
    );
    //fetchAnimes(); // Fetch the updated list after deleting the animes
  }

  Future<List<Anime>> fetchAnimes() async {
    final List<Map<String, dynamic>> maps = await database.query('animes');
    return List.generate(maps.length, (i) {
      return Anime(
        id: maps[i]['id'],
        title: maps[i]['title'],
        rating: maps[i]['rating'],
      );
    });
  }

  Future<void> updateAnime(Anime anime) async {
    final db = await database;
    await db.update(
      'animes',
      anime.toMap(),
      where: 'id = ?',
      whereArgs: [anime.id],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anime List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Anime Title',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: ratingController,
              decoration: InputDecoration(
                labelText: 'Anime Rating',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text;
              final rating = int.tryParse(ratingController.text) ?? 0;
              final anime = Anime(id: lastID++, title: title, rating: rating);
              insertAnime(anime).then((_) {
                setState(() {
                  titleController.clear();
                  ratingController.clear();
                });
              });
            },
            child: Text('Add Anime'),
          ),
          FutureBuilder<List<Anime>>(
            future: fetchAnimes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final animeList = snapshot.data!;
                return Expanded(
                  child: ListView.builder(
                    itemCount: animeList.length,
                    itemBuilder: (context, index) {
                      final anime = animeList[index];
                      return ListTile(
                        title: Text(anime.title),
                        subtitle: Text('Rating: ${anime.rating}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                deleteAnime(anime.id).then((_) {
                                  setState(() {
                                    fetchAnimes();
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
                                    final updatedTitleController = TextEditingController(text: anime.title);
                                    final updatedRatingController = TextEditingController(text: anime.rating.toString());
                                    return AlertDialog(
                                      title: Text('Update Anime'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: updatedTitleController,
                                            decoration: InputDecoration(
                                              labelText: 'Anime Title',
                                            ),
                                          ),
                                          TextField(
                                            controller: updatedRatingController,
                                            decoration: InputDecoration(
                                              labelText: 'Anime Rating',
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
                                            final updatedTitle = updatedTitleController.text;
                                            final updatedRating = int.tryParse(updatedRatingController.text) ?? 0;
                                            final updatedAnime = Anime(
                                              id: anime.id,
                                              title: updatedTitle,
                                              rating: updatedRating,
                                            );
                                            updateAnime(updatedAnime).then((_) {
                                              setState(() {
                                                fetchAnimes();
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

  class Anime {
  final int id;
  final String title;
  final int rating;

  const Anime({
    required this.id,
    required this.title,
    required this.rating,
  });

  // Convert an Anime into a Map. The keys must correspond to the titles of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'rating': rating,
    };
  }

  @override
  String toString() {
    return 'Anime{id: $id, title: $title, rating: $rating}';
  }
}