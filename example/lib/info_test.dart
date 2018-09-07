import 'package:flutter_umpush/flutter_umpush.dart';
import 'package:flutter/material.dart';

class Info extends StatefulWidget {
  final bool isConnected;
  final String registrationId;
  final List notificationList;

  Info({this.isConnected, this.registrationId, this.notificationList});

  @override
  State<StatefulWidget> createState() {
    return new _InfoState();
  }
}

class _InfoState extends State<Info> {
  final TextEditingController tc = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    tc.text = widget.registrationId;

    return new Column(
      children: <Widget>[
        new Row(
          children: <Widget>[
            new Text("Connection State: "),
            new Text(widget.isConnected ? "连接" : "未连接")
          ],
        ),
        new Row(
          children: <Widget>[
            new Text("RegistrationId: "),
          ],
        ),
        new Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 45.0,
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextField(
                  controller: tc,
                  style: TextStyle(color: Colors.blue, fontSize: 11.0),
                ),
              ),
            )
          ],
        ),
        new Padding(
          padding: new EdgeInsets.all(10.0),
          child: new Text("Push history:"),
        ),
        new Expanded(
            child: new ListView.builder(
          itemBuilder: (context, int index) {
            PushMessage obj = widget.notificationList[index];
            return new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new Text("id:"),
                      new Text("${obj.id}")
                    ],
                  ),
                  new Row(
                    children: <Widget>[
                      new Text("title:"),
                      new Text("${obj.title}")
                    ],
                  ),
                  new Row(
                    children: <Widget>[
                      new Text("内容:"),
                      new Text("${obj.message}")
                    ],
                  ),
                ],
              ),
            );
          },
          itemCount: widget.notificationList.length,
        ))
      ],
    );
  }
}
