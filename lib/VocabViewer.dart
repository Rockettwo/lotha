import 'package:flutter/material.dart';
import 'Vocabulary.dart';
import 'Translator.dart';
import 'Helper.dart';

class VocabViewer extends StatefulWidget {
  VocabViewer({Key key, @required this.vocabulary}) : super(key: key);
  final Vocabulary vocabulary;

  @override
  State<StatefulWidget> createState() => _VocabViewerState(vocabulary: vocabulary);
}

// ignore: must_be_immutable
class _VocabViewerState extends State<VocabViewer> {
  // Declare a field that holds the Person data
  final Vocabulary vocabulary;
  List<TranslationResult> _tr;

  // In the constructor, require vocabulary
  _VocabViewerState({@required this.vocabulary});

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Vokabeln"),
      ),
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: vocabulary == null ||
                  (_tr = vocabulary.getList()) == null ? 0 : _tr.length,
              itemBuilder: (context, i) {
                return _buildTileItem(context, i);
              },
              shrinkWrap: true,
              padding: const EdgeInsets.all(20.0),
            ),
          )
        ],
      ),
    );
  }

  _buildTileItem(BuildContext context, int i) {
    return new Dismissible(
      direction: DismissDirection.endToStart,
      key: new ObjectKey(_tr[i]),
      onDismissed: (direction) {
        String originalTmp = _tr[i].original;
        setState(() {
          vocabulary.remove(_tr[i]);
          _tr.remove(_tr[i]);
        });
        Scaffold.of(context).showSnackBar(new SnackBar(
            content: new Text('"' + originalTmp +  '"' + " wurde entfernt")
        ));
      },
      child: ListTile(
        title: Text(_tr[i].original),
        subtitle: Text("Level: " + _tr[i].level.toString()),
        leading: new Image.asset('assets/flags/'+ _tr[i].srcLang +'.png', scale: 3.5,),
        onTap: () {
          Navigator.push(context, new MaterialPageRoute(
              builder: (BuildContext context) => new TranslationViewer(tr: _tr[i]))
          );
        },
      ),
      background: new Center(
        child: new Container(
          color: Colors.red,
          child: Text("Löschen",
            style: TextStyle(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.right,
          ),
          alignment: Alignment(0.9, 0),
        )
      ),
    );
  }

}


// ignore: must_be_immutable
class TranslationViewer extends StatelessWidget {
  // Declare a field that holds the Person data
  final TranslationResult tr;
  Helper _helper;

  // In the constructor, require a Person
  TranslationViewer({Key key, @required this.tr}) : super(key: key){
    _helper = new Helper(tr);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Vokabeln"),
      ),
      body: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: new EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(image: ExactAssetImage('assets/flags/'+ (tr != null ? tr.srcLang : "") +'.png'), height: 15, fit: BoxFit.fitHeight,),
                      _helper.buildTitleWord(tr.original, tr != null ? tr.srcLang : ""),
                    ],
                  )
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tr == null || tr.tl == null ? 0 : tr.tl.length,
                  itemBuilder: (context, i) {
                    return _helper.buildTileItem(i, tr);
                  },
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                ),
              )
            ],
          ),
    );
  }

}

