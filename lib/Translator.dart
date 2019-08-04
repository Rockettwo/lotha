import 'dart:async';
import 'OxfordTranslation.dart';

enum TranslatorType { Oxford, None }

class Translator {
  TranslatorType tType;

  OxfordTranslator oxTrans;

  String srcLang;
  String tarLang;

  Translator() {
    tType = TranslatorType.Oxford;
    oxTrans = new OxfordTranslator();
    srcLang = "de";
    tarLang = "en";
  }

  Future<TranslationResult> translate(String toTranslate) {
    if (tType == TranslatorType.Oxford) {
      return oxTrans.translate(toTranslate, srcLang, tarLang);
    } else {
      return null;
    }
  }
}

class TranslationResult {
  List<TranslationEntry> tl;
  String original;
  int level;

  String srcLang;
  String tarLang;

  TranslationResult() {
    tl = new List<TranslationEntry>();
    original = "";
    level = 0;

    srcLang = "";
    tarLang = "";
  }

  factory TranslationResult.fromResults(TranslationResult tr) {
    if (tr == null) {
      var trNew = new TranslationResult();
      return trNew;
    }

    var tlNew = new List<TranslationEntry>();
    tlNew.addAll(tr.tl);
    var trNew = new TranslationResult();
    trNew.tl = tlNew;
    trNew.original = tr.original;
    trNew.level = tr.level;

    trNew.srcLang = tr.srcLang;
    trNew.tarLang = tr.tarLang;

    return trNew;
  }

  clear() {
    tl = new List<TranslationEntry>();
    original = "";
    level = 0;

    srcLang = "";
    tarLang = "";
  }

  TranslationResult.fromJson(Map<String, dynamic> parsedJson) {
    var tlListVar = parsedJson['tl'] as List;

    if (tlListVar == null) tlListVar = new List<TranslationEntry>();

    List<TranslationEntry> tlList =
    tlListVar.map((i) => TranslationEntry.fromJson(i)).toList();

    tl = tlList;
    level = parsedJson['level'];
    original = parsedJson['original'];
    srcLang = parsedJson['srcLang'];
    tarLang = parsedJson['tarLang'];
  }

  Map<String, dynamic> toJson() => {
    'tl': tl.map((i) => i.toJson()).toList(),
    'level': level,
    'original': original,
    'srcLang' : srcLang,
    'tarLang' : tarLang
  };
}

class TranslationEntry {
  String wordType;
  String category;
  List<Translation> translations;
  List<ExampleEntry> examples;

  String information;

  TranslationEntry() {
    wordType = "";
    category = "";
    translations = new List<Translation>();
    examples = new List<ExampleEntry>();
    information = "";
  }

  TranslationEntry.fromJson(Map<String, dynamic> parsedJson) {
    var translationsListVar = parsedJson['translations'] as List;
    var examplesListVar = parsedJson['examples'] as List;

    if (translationsListVar == null)
      translationsListVar = new List<Translation>();
    if (examplesListVar == null) examplesListVar = new List<ExampleEntry>();

    List<Translation> translationsList =
    translationsListVar.map((i) => Translation.fromJson(i)).toList();
    List<ExampleEntry> examplesList =
    examplesListVar.map((i) => ExampleEntry.fromJson(i)).toList();

    wordType = parsedJson['wordType'];
    category = parsedJson[category];
    translations = translationsList;
    examples = examplesList;
    information = parsedJson['information'];
  }

  Map<String, dynamic> toJson() => {
    'wordType': wordType,
    'category': category,
    'translations': translations.map((i) => i.toJson()).toList(),
    'examples': examples.map((i) => i.toJson()).toList(),
    'information': information
  };
}

class Translation {
  String translation = "";
  String notes = "";

  Translation({this.translation, this.notes});

  Translation.fromJson(Map<String, dynamic> json) {
    translation = json['translation'];
    notes = json['notes'];
  }

  Map<String, dynamic> toJson() => {'translation': translation, 'notes': notes};
}

class ExampleEntry {
  String category;
  String original;
  String translated;

  ExampleEntry({this.category, this.original, this.translated});

  ExampleEntry.fromJson(Map<String, dynamic> json) {
    category = json['category'];
    original = json['original'];
    translated = json['translated'];
  }

  Map<String, dynamic> toJson() =>
      {'category': category, 'original': original, 'translated': translated};
}
