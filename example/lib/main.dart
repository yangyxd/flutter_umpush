import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_umpush/flutter_umpush.dart';
import 'package:flutter_umpush_example/alias_test.dart';
import 'package:flutter_umpush_example/info_test.dart';
import 'package:flutter_umpush_example/push_test.dart';
import 'package:flutter_umpush_example/tag_test.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isConnected = false;
  String registrationId;
  List notificationList = [];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startupJpush();

    FlutterUmPush.addConnectionChangeListener((bool connected) {
      setState(() {
        /// 是否连接，连接了才可以推送
        print("连接状态改变:$connected");
        this.isConnected = connected;
        if (connected) {
          FlutterUmPush.getRegistrationID().then((String regId) {
            print("主动获取设备号:$regId");
            setState(() {
              this.registrationId = regId;
            });
          });
        }
      });
    });

    FlutterUmPush.addnetworkDidLoginListener((String registrationId) {
      setState(() {
        /// 用于推送
        print("收到设备号:$registrationId");
        this.registrationId = registrationId;
      });
    });

    FlutterUmPush
        .addReceiveNotificationListener((PushMessage notification) {
      setState(() {
        /// 收到推送
        print("收到推送提醒: $notification");
        notificationList.add(notification);
      });
    });

    FlutterUmPush
        .addReceiveOpenNotificationListener((PushMessage notification) {
      setState(() {
        print("打开了推送提醒: $notification");

        /// 打开了推送提醒
        notificationList.add(notification);
      });
    });

    FlutterUmPush.addReceiveCustomMsgListener((PushMessage msg) {
      setState(() {
        print("收到推送消息提醒: $msg");

        /// 打开了推送提醒
        notificationList.add(msg);
      });
    });
  }

  void _startupJpush() async {
    print("初始化jpush");
    await FlutterUmPush.startup();
    print("初始化jpush成功");
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('UMPush Example'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                registrationId = await FlutterUmPush.getRegistrationID();
                setState(() { });
              },
            )
          ],
        ),
        body: new IndexedStack(
          children: <Widget>[
            new Info(
              notificationList: notificationList,
              registrationId: registrationId,
              isConnected: isConnected,
            ),
            new TagSet(),
            new AliasSet(),
            new PushTest()
          ],
          index: _index,
        ),
        bottomNavigationBar: new BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
                title: new Text("Info"), icon: new Icon(Icons.info)),
            new BottomNavigationBarItem(
                title: new Text("Tag"), icon: new Icon(Icons.tag_faces)),
            new BottomNavigationBarItem(
                title: new Text("Alias"), icon: new Icon(Icons.nature)),
          ],
          onTap: (int index) {
            setState(() {
              _index = index;
            });
          },
          currentIndex: _index,
        ),
      ),
    );
  }
}
