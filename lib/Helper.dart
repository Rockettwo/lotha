import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/gestures.dart';
import 'Translator.dart';


class Helper {
  TranslationResult tr;
  FlutterTts flutterTts = new FlutterTts();


  Helper(TranslationResult tr) {
    this.tr = tr;
  }

  /// ----------------- Text to speech ----------------- ///
  Future _speak(String lang, String text) async{


    //List<dynamic> languages = await flutterTts.getLanguages;

    if (lang == 'de') {
      lang = "de-DE";
    } else if (lang == 'en') {
      lang = "en-US";
    } else {
      lang = "";
    }

    await flutterTts.setLanguage(lang);

    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    await flutterTts.speak(text);
  }


  /// ----------------- Fill items ----------------- ///


  Widget buildTitleWord(String word, String lang) {
    return new GestureDetector(onTap: () => _speak(lang, word), child: new Text("  " + word, style: TextStyle(fontSize: 20)));
  }

  Widget buildTileItem(int i, TranslationResult _tr) {

    if ((_tr == null || _tr.tl == null || _tr.tl.length == 0) && i == 0)
      return new ListTile(
      title: new Text("Keine Übersetzung gefunden", style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic), textAlign: TextAlign.center,)
    );

    tr = _tr;
    if (tr.tl[i].examples.length > 0) {
      return new ExpansionTile(
        title: _buildTileContent(i),
        children: <Widget>[
          new Column(
            children: _buildExpandableContent(tr.tl[i]),
          )
        ],
      );
    } else {
      return new ListTile(
        title: _buildTileContent(i),
      );
    }
  }

  _buildTileContent(int i) {
    if (tr.tl[i].translations == null || tr.tl[i].translations.length == 0) {
      return new Text(
        "Related examples",
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    if (_isEmptyStr(tr.tl[i].category) && _isEmptyStr(tr.tl[i].information)) {
      return new Text.rich(_textFromTranslation(i));
    }

    double fs = 11;
    var t = TextSpan(text: "(", style: TextStyle(fontSize: fs));

    if (_isEmptyStr(tr.tl[i].category)) {
      return new Text.rich(
        TextSpan(
          text: "",
          children: <TextSpan>[
            t,
            TextSpan(
                text: tr.tl[i].information,
                style: TextStyle(fontSize: fs, fontStyle: FontStyle.italic)),
            TextSpan(text: ")", style: TextStyle(fontSize: fs)),
            _textFromTranslation(i)
          ],
        ),
      );
    } else if (_isEmptyStr(tr.tl[i].information)) {
      return new Text.rich(
        TextSpan(
          text: "",
          children: <TextSpan>[
            t,
            TextSpan(text: tr.tl[i].category, style: TextStyle(fontSize: fs)),
            TextSpan(text: ")", style: TextStyle(fontSize: fs)),
            _textFromTranslation(i)
          ],
        ),
      );
    } else {
      return new Text.rich(
        TextSpan(
          text: "",
          children: <TextSpan>[
            t,
            TextSpan(
                text: tr.tl[i].category +
                    (tr.tl[i].information.length > 0 ? " |" : ""),
                style: TextStyle(fontSize: fs, fontStyle: FontStyle.normal)),
            TextSpan(
                text: (tr.tl[i].category.length > 0 &&
                    tr.tl[i].information.length > 0
                    ? " "
                    : "") +
                    tr.tl[i].information,
                style: TextStyle(fontSize: fs, fontStyle: FontStyle.italic)),
            TextSpan(text: ")", style: TextStyle(fontSize: fs)),
            _textFromTranslation(i)
          ],
        ),
      );
    }
  }

  _buildExpandableContent(TranslationEntry entry) {
    List<Widget> columnContent = [];

    for (var ex in entry.examples) {
      columnContent.add(new ListTile(
          title: new GestureDetector(onTap: () => _speak(tr.srcLang, ex.original), child: new Text(ex.original)),
          subtitle: new GestureDetector(onTap: () => _speak(tr.tarLang, ex.translated), child: new Text(ex.translated, textAlign: TextAlign.right))
      ));
    }

    return columnContent;
  }

  TextSpan _textFromTranslation(int i) {
    List<TextSpan> tsList = new List<TextSpan>();

    String trailingNewLine =
    !_isEmptyStr(tr.tl[i].category) || !_isEmptyStr(tr.tl[i].information)
        ? "\n"
        : "";

    for (Translation trans in tr.tl[i].translations) {
      tsList.add(new TextSpan(
          text: trailingNewLine + trans.translation,
          recognizer: new TapGestureRecognizer()..onTap = () => _speak(tr.tarLang, trans.translation),
          children: <TextSpan>[
            TextSpan(
              text: trans.notes != "" ? "   (" + trans.notes + ")" : "",
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ]));
      trailingNewLine = "\n";
    }
    return new TextSpan(text: "", children: tsList);
  }

  bool _isEmptyStr(String s) {
    if (s == null || s == "")
      return true;
    else
      return false;
  }

}