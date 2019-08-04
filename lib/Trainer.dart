import 'Vocabulary.dart';
import 'Translator.dart';

class Trainer {
  TranslationResult actTr;
  String actWord;
  Vocabulary _vocabulary;

  bool vocAvailable;

  Trainer(Vocabulary voc) {
    _vocabulary = voc;
    actTr = _vocabulary.getRandom();
  }

  void setNext() {
    actTr = _vocabulary.getRandom();
  }

  String getWord() {
    if (actTr != null && actTr.tl != null && actTr.tl.length != 0) {
      actWord = actTr.original;
      vocAvailable = true;
      return actWord;
    } else {
      vocAvailable = false;
      return "Keine Vokabeln vorhanden";
    }
  }

  List<String> getAllPossibleWords(String translation) {
    List<String> wordList = List<String>();

    RegExp exp1 = new RegExp(r"\((.*?)\)");
    RegExp exp2 = new RegExp(r"\[(.*?)\]([\ ]*)");
    RegExp exp3 = new RegExp(r"(\[.*?\])[\ ]*");
    RegExp exp4 = new RegExp(r"(-)");

    String newString = translation.replaceAllMapped(exp1, (match) {return '';});
    Match m;
    if ((m = exp2.firstMatch(newString)) != null) {
      newString = m.group(1);
      if (m.groupCount == 2)
        newString += m.group(2);
      newString = newString.replaceAll(new RegExp("  "), ' ');

      wordList.add((newString + translation.replaceAll(exp3, '')).replaceAll(exp4, " "));
      wordList.add((translation.replaceAll(exp3, '')).replaceAll(exp4, " "));
    }

    wordList.add(translation.replaceAll(exp4, " "));

    return wordList;
  }

  bool checkResult(String enteredWord) {
    if (actTr == null || enteredWord.length == 0) return false;

    for (var trEntry in actTr.tl) {
      for (var translationStr in trEntry.translations) {
        for (var translation in getAllPossibleWords(translationStr.translation)) {
          if (translation.toLowerCase().compareTo(
              enteredWord.toLowerCase()) == 0) {
            _vocabulary.incrementLevel(actTr);
            return true;
          }
        }
      }
    }

    _vocabulary.decrementLevel(actTr);
    return false;
  }
}
