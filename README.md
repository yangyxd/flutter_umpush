# flutter_umpush

Flutter 友盟推送
正在开发中。目前安卓平台基本完成。

## ROADMAP

* [ ] ios
* [x] android
* [x] 集成notification
* [x] 集成message
* [x] 集成alias
* [x] 集成tags
* [x] 可以运行的例子
* [ ] 用户可相互自行推送


## 集成过程

### 准备工作

在 pubspec.yaml 中加入 flutter-umpush 

### 申请key

进入[这里](http://message.umeng.com/list/new/app)创建或添加已有应用。然后可以在应用信息中看到 Appkey、Umeng Message Secret
同时在应用信息中可以设置包名为你的app包名。
详细信息参考开发文档(https://developer.umeng.com/?refer=UPush)

#### ios 证书申请

同安卓一样进入（http://message.umeng.com/list/apps）新建应用。
详情参考iOS开发文档(https://developer.umeng.com/docs/66632/detail/66734)

### ios 集成


### Android 集成

1. 将下载回来SDK中（或本项目example）的 push 文件夹复制到你项目的 android 目录中。
2. 在 push 的 libs 中将缺少的so、jar补全，参考下图

![image](https://github.com/yangyxd/flutter_umpush/blob/master/raw/img001.png)

3. 修改 android\settings.gradle 文件，加入include ':push'
```
include ':app',':push'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
...
```

4. 修改 android\app\build.gradle ，在 android 区域中添加 manifestPlaceholders 和 ndk

```

android {
  ...
  
         // 添加的内容
  
         manifestPlaceholders = [
                UMPUSH_PKGNAME : applicationId,
                UMPUSH_APPKEY : "5b8c9800f29d9836ac000017", //Push上注册的包名对应的appkey.
                UMPUSH_CHANNEL : "umpush",
                UMENG_MESSAGE_SECRET : "b11af04a78ddc9c6ca246a7dc8c275d7",
        ]

        ndk {
            //选择要添加的对应cpu类型的.so库。
            abiFilters 'x86', 'x86_64',  'armeabi-v7a'
            // abiFilters 'armeabi-v7a'
            // 还可以添加 'x86', 'x86_64', 'mips', 'mips64', 'armeabi', 'armeabi-v7a', 'arm64-v8a'
        }
 
  
  ...
}

```

5. 修改 AndroidManifest.xml

```
将 application 中的 

android:name="io.flutter.app.FlutterApplication" 

修改为 

android:name="com.yangyxd.flutterumpush.MainApplication"

```

## 使用插件

在 initState() 中初始化和添加监听

```
    await FlutterUmPush.startup();

    FlutterUmPush.addConnectionChangeListener((bool connected) {
      setState(() {
        /// 是否连接，连接了才可以推送
        print("连接状态改变:$connected");
        this.isConnected = connected;
        if (connected) {
          FlutterUmPush.getRegistrationID().then((String regId) {
            print("主动获取设备号:$regId");
            setState(() {});
          });
        }
      });
    });

    FlutterUmPush.addnetworkDidLoginListener((String registrationId) {
      setState(() {
        /// 用于推送
        print("收到设备号:$registrationId");
      });
    });

    FlutterUmPush
        .addReceiveNotificationListener((PushMessage notification) {
      setState(() {
        /// 收到推送
        print("收到推送提醒: $notification");
      });
    });

    FlutterUmPush
        .addReceiveOpenNotificationListener((PushMessage notification) {
      setState(() {
        print("打开了推送提醒: $notification");
      });
    });

    FlutterUmPush.addReceiveCustomMsgListener((PushMessage msg) {
      setState(() {
        print("收到推送消息提醒: $msg");
      });
    });
    
```

## License MIT

## 感谢
本项目直接拿了雪亮的极光推送框架来改的，省了不少时间，在此表示感谢。
极光推送：https://github.com/best-flutter/flutter_jpush

## 欢迎提交issue或者加入QQ群325337654

