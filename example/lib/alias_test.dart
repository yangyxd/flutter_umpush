import 'package:flutter/material.dart';
import 'package:flutter_umpush/flutter_umpush.dart';

class AliasSet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _AliasSetState();
  }
}

class _AliasSetState extends State<AliasSet> {
  String _text = "Test alias";
  String _textType = "www.qq.com";
  String _alias = "";

  void _onChanged(String text) {
    _text = text;
  }

  @override
  void initState() {
    getAlias();

    super.initState();
  }

  void getAlias() {
    print("不支持");
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Row(
          children: <Widget>[
            new Text("Device alias:"),
            new Expanded(child: new Text(_alias))
          ],
        ),
        new Row(
          children: <Widget>[
            new Text("Alias:"),
            new Expanded(
                child: new TextField(
              onChanged: _onChanged,
              controller: new TextEditingController(text: _text ?? ""),
            ))
          ],
        ),
        new Row(
          children: <Widget>[
            new Text("Alias Type:"),
            new Expanded(
                child: new TextField(
                  onChanged: (String text) {
                    _textType = text;
                  },
                  controller: new TextEditingController(text: _textType ?? ""),
                ))
          ],
        ),
        new RaisedButton(
          onPressed: () async {
            PushResult result = await FlutterUmPush.addAlias(_text, _textType);
            if (result.isOk) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return new AlertDialog(
                      title: new Text("提醒"),
                      content: new Text("添加成功,[${result.result}]"),
                    );
                  });
            } else {
              showDialog(
                  context: context,
                  builder: (context) {
                    return new AlertDialog(
                      title: new Text("提醒"),
                      content: new Text("添加失败"),
                    );
                  });
            }
          },
          color: Colors.blueAccent,
          textColor: Colors.white,
          child: new Text("Add alias"),
        ),
        new RaisedButton(
          onPressed: () async {
            PushResult result = await FlutterUmPush.setAlias(_text, _textType);
            if (result.isOk) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return new AlertDialog(
                      title: new Text("提醒"),
                      content: new Text("设置成功,[${result.result}]"),
                    );
                  });
            } else {
              showDialog(
                  context: context,
                  builder: (context) {
                    return new AlertDialog(
                      title: new Text("提醒"),
                      content: new Text("设置失败"),
                    );
                  });
            }
          },
          color: Colors.blueAccent,
          textColor: Colors.white,
          child: new Text("Set alias"),
        ),
        new SizedBox(
          height: 8.0,
        ),
      ],
    );
  }
}
