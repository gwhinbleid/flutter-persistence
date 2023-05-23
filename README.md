# Persistenz mit SQLite in Flutter

## SQLite
Plugin für Flutter. Unterstützt iOS, Android und MacOS

## Schritte
1) Dependencies hinzufügen
2) Datenmodell definieren
3) Datenbank öffnen
4) Tabelle erstellen
5) Eintrag in die Datenbank einfügen
6) Einträge auslesen
7) Eintrag aktualisieren
8) Eintrag löschen

# Dependencies hinzufügen

'sqflite' und path packages importieren, um mit der SQLite Datenbank zu arbeiten.

* Das sqflite Paket stellt Klassen und Funktionen zur Verfügung, um mit der SQLite Datenbank zu interagieren
* Die Pfadpakete stellen Funktionen zur Verfügung, um den Ort der Datenbank auf der Festplatte zu definieren


```js
dependencies:
  flutter:
    sdk: flutter
  sqflite:
  path:
```

```js
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
```

# Datenmodell definieren

Bevor eine Tabelle erstellt wird, muss das Datenmodell erst definiert werden. Als Beispiel werden folgende Daten werden definiert:

| Key          | Beschreibung        |
| -------------| --------------------|
| id           | eine eindeutige ID  |
| name         | ein Name            |
| rating       | eine Bewertung      |

```js
class Anime {
  final int id;
  final String name;
  final int rating;

  const Anime({
    required this.id,
    required this.name,
    required this.rating,
  });
}
```

# Datenbank öffnen

Um Daten aus der Datenbank zu lesen oder zu schreiben, muss vorher eine Verbindung zur Datenbank erstellt werden. Dies beinhaltet zwei Schritte:

* Definieren des Pfades der Datenbank mit `getDatabasesPath()` in Kombination mit der `join` Funktion des path package.
* Öffnen der Datenbank mit `openDatabase()` aus der sqflite Bibliothek.

```js
// Avoid errors caused by flutter upgrade.
// Importing 'package:flutter/widgets.dart' is required.
WidgetsFlutterBinding.ensureInitialized();
// Open the database and store the reference.
final database = openDatabase(
  // Set the path to the database. Note: Using the `join` function from the
  // `path` package is best practice to ensure the path is correctly
  // constructed for each platform.
  join(await getDatabasesPath(), 'anime_database.db'),
);
```

# Tabelle erstellen

Als Beispiel wird eine Tabelle mit verschiedenen Animes erstellt. Die Tabelle nutzt das vorher definierte Datenmodell `Anime`, welches aus einer `id`, einem `name` sowie einem `rating` besteht. Diese werden als drei Spalten der Animetabelle repräsentiert.


| Key          | Datentyp                               |
| -------------| ---------------------------------------|
| id           | INTEGER (Dart int) [Primärschlüssel]   |
| name         | TEXT (Dart String)                     |
| rating       | INTEGER (Dart int)                     |

```js
final database = openDatabase(
  // Set the path to the database. Note: Using the `join` function from the
  // `path` package is best practice to ensure the path is correctly
  // constructed for each platform.
  join(await getDatabasesPath(), 'anime_database.db'),
  // When the database is first created, create a table to store animes.
  onCreate: (db, version) {
    // Run the CREATE TABLE statement on the database.
    return db.execute(
      'CREATE TABLE animes(id INTEGER PRIMARY KEY, name TEXT, rating INTEGER)',
    );
```

# Eintrag in die Datenbank einfügen

Die Datenbank ist nun vorbereitet und man kann jetzt Einträge schreiben und auslesen.

Einträge werden wie folgt eingefügt:

* Anime in eine Map konvertieren
* insert() Methode aufrufen, um die Map in die Tabelle hinzuzufügen


```js
class Anime {
  final int id;
  final String name;
  final int rating;

  const Anime({
    required this.id,
    required this.name,
    required this.rating,
  });

  // Convert an Anime into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
    };
  }

  // Implement toString to make it easier to see information about
  // each anime when using the print statement.
  @override
  String toString() {
    return 'Anime{id: $id, name: $name, rating: $rating}';
  }
}

// Define a function that inserts anime into the database
Future<void> insertAnime(Anime anime) async {
  // Get a reference to the database.
  final db = await database;

  // Insert the Anime into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same anime is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'animes',
    anime.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Create an Anime and add it to the anime table
var pokemon = const Anime(
  id: 0,
  name: 'Pokémon',
  rating: 4,
);

await insertAnime(pokemon);
```
# Einträge auslesen

Nachdem die Datenbank befüllt ist, kann man nach einem spezifischen Anime-Eintrag oder eine Liste ausgeben lassen.

* Query über die Anime Tabelle gibt eine List<Map> zurück
* Die List<Map> in eine List<Anime> konvertieren

```js
// A method that retrieves all the animes from the animes table.
Future<List<Anime>> animes() async {
  // Get a reference to the database.
  final db = await database;

  // Query the table for all The Anime.
  final List<Map<String, dynamic>> maps = await db.query('animes');

  // Convert the List<Map<String, dynamic> into a List<Anime>.
  return List.generate(maps.length, (i) {
    return Anime(
      id: maps[i]['id'],
      name: maps[i]['name'],
      rating: maps[i]['rating'],
    );
  });
}

// Now, use the method above to retrieve all the animes.
print(await animes()); // Prints a list that include Pokémon.
```

# Eintrag aktualisieren

Bestehende Einträge in der Datenbank kann man mittels der `update()` Methode aktualisieren.

* Anime in eine Map konvertieren
* `Where` benutzen, um den richtigen Eintrag zu aktualisieren

```js
Future<void> updateAnime(Anime anime) async {
  // Get a reference to the database.
  final db = await database;

  // Update the given Anime.
  await db.update(
    'animes',
    anime.toMap(),
    // Ensure that the Anime has a matching id.
    where: 'id = ?',
    // Pass the Anime's id as a whereArg to prevent SQL injection.
    whereArgs: [anime.id],
  );
}

// Update Anime's rating and save it to the database.
pokemon = Anime(
  id: pokemon.id,
  name: pokemon.name,
  rating: pokemon.rating + 1,
);
await updateAnime(pokemon);

// Print the updated results.
print(await animes()); // Prints Anime with rating 5.
```

# Einträge löschen

Um einen Eintrag zu löschen, nutzt man die Methode `delete()`.
Mittels `where` spezifizieren wir den Eintrag, den wir letztendlich löschen wollen.

```js
Future<void> deleteAnime(int id) async {
  // Get a reference to the database.
  final db = await database;

  // Remove the Anime from the database.
  await db.delete(
    'animes',
    // Use a `where` clause to delete a specific anime.
    where: 'id = ?',
    // Pass the Anime's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}
```
