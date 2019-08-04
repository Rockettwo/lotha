import 'dart:async' show Future;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'Translator.dart';
import 'ApiCredentials.dart';

class OxfordTranslator {
  OxTranslationResultJson trJs;
  TranslationResult tr;

  OxfordTranslator() {
    tr = new TranslationResult();
  }

  Future<TranslationResult> translate(String toTranslate,
      [String language = "de", String targetLang = "en"]) async {
    String jsonString = await _translateInBackground(
        _translations(toTranslate, language, targetLang));
    _parseOxTranslation(jsonString);

    return fillFromJson(trJs);
  }

  String _translations(String toTranslate, String language, String targetLang) {
    final String word = toTranslate;
    final String wordId = word
        .toLowerCase(); //word id is case sensitive and lowercase is required
    return "https://od-api.oxforddictionaries.com/api/v2/translations/"+ language+"/"+targetLang+"/"+wordId+"?strictMatch=false";
  }

  Future<String> _translateInBackground(String params) async {
    String translation = "";
    try {
      Uri uri = Uri.parse(params);

      APICredentials apc = APICredentials();

      var request = await HttpClient().getUrl(uri);
      request.headers.add("Accept", "application/json");
      request.headers.add("app_id", apc.appIdOxford);
      request.headers.add("app_key", apc.appKeyOxford);
      // sends the request
      var response = await request.close();

      if (response.statusCode != 200) throw Exception();

      // transforms and prints the response
      await for (var contents in response.transform(Utf8Decoder())) {
        //print(contents);
        translation += contents;
      }

      //print('Here');
    } catch (Exception) {
      translation = 'Keine Übersetzung vorhanden.';
    }
    return translation;
  }

  void _parseOxTranslation(String jsonString) {
    if (jsonString.length < 100) {
      trJs = null;
      return;
    }

    final jsonResponse = json.decode(jsonString);
    trJs = new OxTranslationResultJson.fromJson(jsonResponse);
  }

  TranslationResult fillFromJson(OxTranslationResultJson trJs) {
    if (trJs == null) {
      return null;
    }

    String tarLang = "";

    tr.tl = new List<TranslationEntry>();
    TranslationEntry noTranslations = new TranslationEntry();
    noTranslations.examples = new List<ExampleEntry>();

    for (var result in trJs.results) {
      tr.original = result.word;
      tr.srcLang = trJs.results[0].language;

      for (var lexicalEntry in result.lexicalEntries) {
        for (var entries in lexicalEntry.entries) {
          for (var sense in entries.senses) {
            TranslationEntry tmpEntry = new TranslationEntry();
            tmpEntry.wordType = lexicalEntry.lexicalCategory;
            List<ExampleEntry> exList = new List<ExampleEntry>();
            for (var example in sense.examples) {
              String translationText = "";
              for (var translation in example.translations) {
                if (translation.language != null && translation.language != "")
                  tarLang = translation.language;
                translationText += translation.text +
                    (translation == example.translations.last ? "" : "\n");
              }
              exList.add(new ExampleEntry(
                  category:
                  example.domains.length == 0 ? "" : example.domains.first,
                  original: example.text,
                  translated: translationText));
            }
            tmpEntry.examples = exList;

            for (var note in sense.notes) {
              tmpEntry.information +=
                  note.text + (sense.notes.last != note ? ", " : "");
            }

            for (var categoryVar in sense.domains) {
              var category = categoryVar.text;
              tmpEntry.category +=
                  category + (sense.domains.last.text != category ? ", " : "");
            }

            for (var translation in sense.translations) {
              if (translation.language != null && translation.language != "")
                tarLang = translation.language;
              tmpEntry.translations.add(new Translation(
                  translation: translation.text,
                  notes: translation.notes.length != 0
                      ? translation.notes.first.text
                      : ""));
            }

            if (tmpEntry.translations.length == 0) {
              noTranslations.examples.addAll(exList);
            } else {
              tr.tl.add(tmpEntry);
            }
          }
        }
      }
    }
    if (noTranslations.examples.length > 0) {
      tr.tl.add(noTranslations);
    }

    tr.tarLang = tarLang;

    return tr;
  }
}

//// -------------------------------------------------------------------------------- ////
//// ------------------------------------- JSON ------------------------------------- ////
//// -------------------------------------------------------------------------------- ////

class OxTranslationResultJson {
  final OxMetadata metadata;
  List<OxResult> results;
  final bool empty;

  OxTranslationResultJson({this.metadata, this.results, this.empty});

  factory OxTranslationResultJson.fromJson(Map<String, dynamic> parsedJson) {
    var resultListVar = parsedJson['results'] as List;

    if (resultListVar == null) resultListVar = new List<OxResult>();

    List<OxResult> resultList =
    resultListVar.map((i) => OxResult.fromJson(i)).toList();

    return new OxTranslationResultJson(
      metadata: OxMetadata.fromJson(parsedJson['metadata']),
      results: resultList,
      empty: false,
    );
  }
}

class OxMetadata {
  final String provider;

  OxMetadata({this.provider});

  factory OxMetadata.fromJson(Map<String, dynamic> parsedJson) {
    return new OxMetadata(provider: parsedJson['provider']);
  }
}

class OxResult {
  final String id;
  final String language;
  final List<OxLexicalEntry> lexicalEntries;
  final String type;
  final String word;

  OxResult({this.id, this.language, this.lexicalEntries, this.type, this.word});

  factory OxResult.fromJson(Map<String, dynamic> parsedJson) {
    var lexicalEntriesListVar = parsedJson['lexicalEntries'] as List;

    if (lexicalEntriesListVar == null)
      lexicalEntriesListVar = new List<OxLexicalEntry>();

    List<OxLexicalEntry> lexicalEntriesList =
        lexicalEntriesListVar.map((i) => OxLexicalEntry.fromJson(i)).toList();

    return new OxResult(
        id: parsedJson['id'],
        language: parsedJson['language'],
        lexicalEntries: lexicalEntriesList,
        type: parsedJson['type'],
        word: parsedJson['word']);
  }
}

class OxLexicalEntry {
  final List<OxEntry> entries;
  final String language;
  final String lexicalCategory;
  final String text;

  OxLexicalEntry(
      {this.entries, this.language, this.lexicalCategory, this.text});

  factory OxLexicalEntry.fromJson(Map<String, dynamic> parsedJson) {
    var entriesListVar = parsedJson['entries'] as List;

    if (entriesListVar == null) entriesListVar = List<OxEntry>();

    List<OxEntry> entriesList =
        entriesListVar.map((i) => OxEntry.fromJson(i)).toList();

    return new OxLexicalEntry(
        entries: entriesList,
        language: parsedJson['language'],
        lexicalCategory: parsedJson['lexicalCategory']['text'] ,
        text: parsedJson['text']);
  }
}

class OxEntry {
  final List<OxGrammaticalFeature> grammaticalFeatures;
  final String homographNumber;
  final List<OxNote> notes;
  final List<OxSense> senses;

  OxEntry(
      { this.grammaticalFeatures,
        this.homographNumber,
        this.notes,
        this.senses});

  factory OxEntry.fromJson(Map<String, dynamic> parsedJson) {
    var grammaticalFeaturesListVar = parsedJson['grammaticalFeatures'] as List;
    var notesListVar = parsedJson['notes'] as List;
    var sensesListVar = parsedJson['senses'] as List;

    if (grammaticalFeaturesListVar == null)
      grammaticalFeaturesListVar = List<OxGrammaticalFeature>();
    if (notesListVar == null) notesListVar = List<OxNote>();
    if (sensesListVar == null) sensesListVar = List<OxSense>();

    List<OxGrammaticalFeature> grammaticalFeaturesList =
        grammaticalFeaturesListVar
            .map((i) => OxGrammaticalFeature.fromJson(i))
            .toList();
    List<OxNote> notesList =
        notesListVar.map((i) => OxNote.fromJson(i)).toList();
    List<OxSense> sensesList =
        sensesListVar.map((i) => OxSense.fromJson(i)).toList();

    return new OxEntry(
        grammaticalFeatures: grammaticalFeaturesList,
        homographNumber: parsedJson['homographNumber'],
        notes: notesList,
        senses: sensesList);
  }
}

class OxGrammaticalFeature {
  final String text;
  final String type;

  OxGrammaticalFeature({this.text, this.type});

  factory OxGrammaticalFeature.fromJson(Map<String, dynamic> parsedJson) {
    return new OxGrammaticalFeature(
        text: parsedJson['text'], type: parsedJson['type']);
  }
}

class OxNote {
  final String text;
  final String type;

  OxNote({this.text, this.type});

  factory OxNote.fromJson(Map<String, dynamic> parsedJson) {
    return new OxNote(text: parsedJson['text'], type: parsedJson['type']);
  }
}

class OxSense {
  final List<OxDomains> domains;
  final List<OxCrossReference> crossReferences;
  final List<OxExample> examples;
  final String id;
  final List<OxNote> notes;
  final List<OxTranslation> translations;

  OxSense(
      { this.domains,
        this.crossReferences,
        this.examples,
        this.id,
        this.notes,
        this.translations});

  factory OxSense.fromJson(Map<String, dynamic> parsedJson) {
    var domainsListVar = parsedJson['domains'] as List;
    var crossReferencesListVar = parsedJson['crossReferences'] as List;
    var examplesListVar = parsedJson['examples'] as List;
    var notesListVar = parsedJson['notes'] as List;
    var translationsListVar = parsedJson['translations'] as List;

    if (domainsListVar == null) domainsListVar = List<OxDomains>();
    if (crossReferencesListVar == null)
      crossReferencesListVar = List<OxCrossReference>();
    if (examplesListVar == null) examplesListVar = List<OxExample>();
    if (notesListVar == null) notesListVar = List<OxNote>();
    if (translationsListVar == null)
      translationsListVar = List<OxTranslation>();

    List<OxDomains> domainsList =
        domainsListVar.map((i) => OxDomains.fromJson(i)).toList();
    List<OxCrossReference> crossReferencesList = crossReferencesListVar
        .map((i) => OxCrossReference.fromJson(i))
        .toList();
    List<OxExample> examplesList =
        examplesListVar.map((i) => OxExample.fromJson(i)).toList();
    List<OxNote> notesList =
        notesListVar.map((i) => OxNote.fromJson(i)).toList();
    List<OxTranslation> translationsList =
        translationsListVar.map((i) => OxTranslation.fromJson(i)).toList();

    return new OxSense(
        domains: domainsList,
        crossReferences: crossReferencesList,
        examples: examplesList,
        id: parsedJson['id'],
        notes: notesList,
        translations: translationsList);
  }
}

class OxDomains {
  final String id;
  final String text;

  OxDomains({this.id, this.text});

  factory OxDomains.fromJson(Map<String, dynamic> parsedJson) {
    return new OxDomains(
        id: parsedJson['id'],
        text: parsedJson['text']);
  }
}

class OxCrossReference {
  final String id;
  final String text;
  final String type;

  OxCrossReference({this.id, this.text, this.type});

  factory OxCrossReference.fromJson(Map<String, dynamic> parsedJson) {
    return new OxCrossReference(
        id: parsedJson['id'],
        text: parsedJson['text'],
        type: parsedJson['type']);
  }
}

class OxExample {
  final List<String> domains;
  final String text;
  final List<OxTranslation> translations;

  OxExample({this.domains, this.text, this.translations});

  factory OxExample.fromJson(Map<String, dynamic> parsedJson) {
    var domainsListVar = parsedJson['domains'] as List;
    var translationsListVar = parsedJson['translations'] as List;

    if (domainsListVar == null) domainsListVar = List<String>();
    if (translationsListVar == null)
      translationsListVar = List<OxTranslation>();

    List<String> domainsList = List<String>.from(domainsListVar);
    List<OxTranslation> translationsList =
        translationsListVar.map((i) => OxTranslation.fromJson(i)).toList();

    return new OxExample(
        domains: domainsList,
        text: parsedJson['text'],
        translations: translationsList);
  }
}

class OxTranslation {
  final String language;
  final List<OxNote> notes;
  final String text;

  OxTranslation({this.language, this.notes, this.text});

  factory OxTranslation.fromJson(Map<String, dynamic> parsedJson) {
    var notesListVar = parsedJson['notes'] as List;

    if (notesListVar == null) notesListVar = List<OxNote>();

    List<OxNote> notesList =
    notesListVar.map((i) => OxNote.fromJson(i)).toList();

    return new OxTranslation(
        language: parsedJson['language'],
        notes: notesList,
        text: parsedJson['text']);
  }
}
