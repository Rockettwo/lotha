import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:objectdb/objectdb.dart';

import 'Trainer.dart';
import 'Translator.dart';

class Vocabulary {
  List<TranslationResult> _vocabList;
  List<String> lastWords = new List<String>();
  Random _randomGen;
  Trainer trainer;

  // open db
  ObjectDB vocabDB;

  Vocabulary() {
    _vocabList = new List<TranslationResult>();
    _randomGen = new Random(DateTime.now().millisecondsSinceEpoch);
    trainer = new Trainer(this);
  }

  Future<void> init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dbFilePath = [appDocDir.path, 'user.db'].join('/');
    vocabDB = ObjectDB(dbFilePath);

    vocabDB.open();
    List tmpList = await vocabDB.find({
      Op.gte: {'level': -999999}
    });

    _vocabList = tmpList.map((i) => TranslationResult.fromJson(i)).toList();
    _sortList();
    print(_vocabList.length);


    for (int i = 0; i < (_vocabList.length / 2).floor(); ++i) {
      lastWords.add("");
    }
  }

  void dispose() async {
    if (vocabDB != null)
      await vocabDB.close();
  }

  void _sortList() {
    _vocabList.sort((a,b) {
      int t = a.level.compareTo(b.level);
      if (t == 0) {
        return a.original.toLowerCase().compareTo(b.original.toLowerCase());
      } else {
        return t;
      }
    });
  }

  void add(TranslationResult tr) async {
    var result = await vocabDB.find({'original': tr.original});
    if (result.length > 0) {
      print("Already added");
    } else {
      _vocabList.add(tr);
      _vocabList.sort((a,b) => a.level.compareTo(b.level));
      vocabDB.insert(tr.toJson());
    }
  }

  void remove(TranslationResult tr) async {
    var result = await vocabDB.remove({'original': tr.original});
    if (result == 0) {
      print("Already removed");
    } else {
      _vocabList.remove(tr);
    }
  }

  void incrementLevel(TranslationResult tr) async{
    var result = await vocabDB.find({'original': tr.original});
    if (result.length == 0) {
      print("No such entry");
    } else {
      vocabDB.update({'original': tr.original}, {'level': tr.level + 1});
      tr.level += 1;
      _sortList();
    }
  }

  void decrementLevel(TranslationResult tr) async{
    var result = await vocabDB.find({'original': tr.original});
    if (result.length == 0) {
      print("No such entry");
    } else {
      vocabDB.update({'original': tr.original}, {'level': tr.level - 1});
      tr.level -= 1;
      _sortList();
    }
  }

  List<TranslationResult> getList() {
    return _vocabList;
  }

  TranslationResult getRandom() {
    if (_vocabList.length != 0) {
      int randomNumber;
      for (int i = 0; i < 10; ++i) {
        double randDouble = pow(_randomGen.nextDouble(), 3);
        randomNumber = (randDouble * (_vocabList.length - 1)).round();
        if (lastWords.firstWhere((x) => _vocabList[randomNumber].original.compareTo(x) == 0, orElse: () => "") == "") {
          lastWords.removeAt(0);
          lastWords.add(_vocabList[randomNumber].original);
          break;
        }
      }
      return _vocabList[randomNumber];
    } else {
      return null;
    }
  }
}
