import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:core';
import 'Translator.dart';
import 'Vocabulary.dart';
import 'VocabViewer.dart';
import 'Helper.dart';

class TranslatorPage extends StatefulWidget {
  TranslatorPage({Key key}) : super(key: key);

  @override
  _TranslatorPageState createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  TranslationResult _tr = new TranslationResult();

  final toTranslateController = TextEditingController();
  final toTrainController = TextEditingController();
  final Translator _translator = new Translator();
  final Vocabulary _vocabulary = new Vocabulary();
  Helper _helper;

  Icon searchIcon = new Icon(Icons.search);
  Widget appBarWidget;
  int _currentIndex = 0;
  int _lastIndex = -1;

  Image langIcon;

  bool nothingFound = false;
  bool solutionShowed = false;
  bool changedLanguage = false;

  BoxDecoration bgTrainer = new BoxDecoration(color: Colors.white);
  Widget trainerButtonWidget = new Text("");
  Widget trainerBodyWidget = new Text("");

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    toTranslateController.dispose();
    _vocabulary.dispose();
    super.dispose();
  }


  Future<void> asyncInit() async {
    await _vocabulary.init();
    setState(() {});
  }

  @override
  void initState() {
    _helper = new Helper(_tr);
    langIcon = new Image.asset('assets/flags/'+ _translator.srcLang +'.png', fit: BoxFit.fitHeight,);
    appBarWidget = new GestureDetector(
      onTap: () {
        searchBarClicked();
      },
      child: new Text("Lotha\'s Übersetzer"),
    );
    super.initState();
      asyncInit();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar:
      new AppBar(centerTitle: true, title: appBarWidget, actions: <Widget>[
        new IconButton(
          icon: searchIcon,
          onPressed: () {
            searchBarClicked();
          },
        ),
      ]),
      drawer: new Drawer(
        child: ListView(
          children: <Widget>[
            new DrawerHeader(
                child: Text(
                  "Lotha Info: \n\n" + _vocabulary.getList().length.toString() + " Übersetzungen",
                  style: TextStyle(fontSize: 20),
                )
            ),
            new ListTile(
              title: Text("Vokabelliste"),
              onTap: () {
                Navigator.push(context, new MaterialPageRoute(
                  builder: (BuildContext context) => new VocabViewer(vocabulary: _vocabulary))
                );
              },
            )
          ],
        ),
      ),
      body: getBodyWidgets()[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            title: Text("Übersetzer"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            title: Text("Trainer"),
          )
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (!(_currentIndex == index)) {
              _currentIndex = index;
              this.searchIcon = new Icon(Icons.search);
              this.appBarWidget = new GestureDetector(
                  onTap: () {
                    searchBarClicked();
                  },
                  child: _currentIndex == 1
                      ? new Text("Lotha\'s Trainer")
                      : new Text("Lotha\'s Übersetzer"));
              this.toTranslateController.clear();
              nextWord();
              this._tr.clear();
              nothingFound = false;
            }
          });
        },
      ),
    );
  }

  /// ----------------- Layouts ----------------- ///

  List<Widget> getBodyWidgets() {
    return <Widget>[
      /// Translator
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _tr == null || _tr.tl == null || nothingFound ? 1 : _tr.tl.length,
              itemBuilder: (context, i) {
                return _helper.buildTileItem(i, _tr);
              },
              shrinkWrap: true,
              padding: const EdgeInsets.all(20.0),
            ),
          )
        ],
      ),

      /// Trainer
      Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                      decoration: bgTrainer,
                      child: Padding(
                        padding: new EdgeInsets.fromLTRB(15, 5, 15, 0),
                        child: Column(children: <Widget>[
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Image(image: ExactAssetImage('assets/flags/'+ (_vocabulary.trainer.actTr != null ? _vocabulary.trainer.actTr.srcLang : "") +'.png'), height: 15, fit: BoxFit.fitHeight,),
                                _helper.buildTitleWord(_vocabulary.trainer.getWord(),_vocabulary.trainer.actTr != null ? _vocabulary.trainer.actTr.srcLang : ""),
                              ],
                            )
                          ),
                          TextField(
                            enabled: _vocabulary.trainer.vocAvailable,
                            autofocus: _vocabulary.trainer.vocAvailable,
                            controller: toTrainController,
                            autocorrect: false,
                            style: new TextStyle(
                                fontSize: 22, color: Colors.black),
                            textAlign: TextAlign.center,
                            onTap: () {
                              if (solutionShowed)
                                nextWord();
                            },
                            onEditingComplete: () {
                              checkWord(toTrainController.text);
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                            },
                          ),
                          trainerButtonWidget,
                        ]),
                      )),
                  trainerBodyWidget,
                ],
              ),
            ),
          )
        ],
      )
    ];
  }

  /// ----------------- On Action Functions ----------------- ///

  void searchBarClicked() {
    setState(() {
      if (changedLanguage || this.searchIcon.icon == Icons.search) {
        changedLanguage = false;
        nothingFound = false;
        _lastIndex = _currentIndex;
        _currentIndex = 0;

        this.toTranslateController.clear();
        this._tr.clear();

        this.searchIcon = new Icon(Icons.close);
        this.appBarWidget = new TextField(
          autofocus: true,
          controller: toTranslateController,
          style: new TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
          decoration: new InputDecoration(
              prefixIcon: new IconButton(
                  icon: langIcon,
                  tooltip: 'Sprache ändern',
                  onPressed: () {
                    String tmp = _translator.srcLang;
                    _translator.srcLang = _translator.tarLang;
                    _translator.tarLang = tmp;
                    changedLanguage = true;
                    langIcon = new Image.asset('assets/flags/'+ _translator.srcLang +'.png', fit: BoxFit.fitHeight,);
                    searchBarClicked();
                  },
                ),
              hintText: " " + _translator.srcLang,
              hintStyle: new TextStyle(color: Colors.white)),
          onEditingComplete: () {
            translate(toTranslateController.text);
            FocusScope.of(context).requestFocus(new FocusNode());
          },
        );
      } else {
        if (!(_currentIndex == _lastIndex)) {
          _currentIndex = _lastIndex;
        }
          this.searchIcon = new Icon(Icons.search);
          this.appBarWidget = new GestureDetector(
              onTap: () {
                searchBarClicked();
              },
              child: _currentIndex == 1
                  ? new Text("Lotha\'s Trainer")
                  : new Text("Lotha\'s Übersetzer"));
          this.toTranslateController.clear();
          nextWord();
          this._tr.clear();
      }
    });
  }

  void translate(String toTranslate) async {
    _tr = await _translator.translate(toTranslate);
    if (_tr == null) {
      _tr = new TranslationResult();
      nothingFound = true;
    } else {
      _vocabulary.add(new TranslationResult.fromResults(_tr));
      nothingFound = false;
    }
    setState(() {});
  }

  void checkWord(String toCheck) {
    if (_vocabulary.trainer.checkResult(toCheck)) {
      bgTrainer = new BoxDecoration(color: Colors.green);
      showSolution();

    } else {
      bgTrainer = new BoxDecoration(color: Colors.red);
      trainerButtonWidget = new RaisedButton(
          child: Text("Lösung"),
          onPressed: () {
            showSolution();
          });
    }
    setState(() {});
  }

  void showSolution() {
    _tr = TranslationResult.fromResults(_vocabulary.trainer.actTr);
    trainerBodyWidget = Expanded(
        child: ListView.builder(
          itemCount: _tr == null || _tr.tl == null ? 0 : _tr.tl.length,
          itemBuilder: (context, i) {
            return _helper.buildTileItem(i, _tr);
          },
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
        ));

    trainerButtonWidget = new RaisedButton(
        child: Text("Nächstes"),
        onPressed: () {
          nextWord();
        });
    solutionShowed = true;
    setState(() {});
  }

  void nextWord() {
    _vocabulary.trainer.setNext();
    bgTrainer = new BoxDecoration(color: Colors.white);
    toTrainController.clear();
    trainerButtonWidget = new Text("");
    trainerBodyWidget = new Text("");
    solutionShowed = false;
    setState(() {});
  }
}
