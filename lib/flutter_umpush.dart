import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

enum AppState { inactive, active, background }

class DataItemBase {
  final Map data;
  DataItemBase(this.data);

  Object getItem(final String key) {
    if (data == null || key == null) return null;
    return data[key];
  }

  String getItemStr(final String key) {
    if (data == null || key == null) return "";
    return data[key];
  }

  int getItemInt(final String key) {
    if (data == null || key == null) return 0;
    Object v = data[key];
    if (v == null || v is int) return v;
    try {
      return int.parse("$v");
    } catch (e) {
      return 0;
    }
  }

  DateTime getDateTime(final String key) {
    if (data == null || key == null) return null;
    Object v = data[key];
    if (v == null || v is DateTime) return v;
    try {
      return DateTime.parse("$v");
    } catch (e) {
      return null;
    }
  }

  double getFloat(final String key) {
    if (data == null || key == null) return 0.0;
    try {
      String v = data[key].toString();
      if (v == null || v.length == 0) return 0.0;
      return double.parse(v);
    } catch (e) {
      return 0.0;
    }
  }

  void setItem(final String key, Object v) {
    if (data == null || key == null) return;
    if (data.containsKey(key)) data.remove(key);
    data[key] = v;
  }

  @override
  String toString() {
    return "${this.runtimeType.toString()}: ${data == null ? null : JsonEncoder().convert(data)}";
  }
}

/// 推送消息
class PushMessage extends DataItemBase {
  PushMessage(Map data, [this.isNotify = false, this.isOpenNotify = false]) : super(data);

  /// 消息是一个通知
  final bool isNotify;
  /// 是否是在打开通知
  final bool isOpenNotify;

  String get id => getItem("id");
  // 消息主体
  String get message => getItem("message");
  // 消息标题
  String get title => getItem("title");
  // extras
  Map get extras => getItem("extras");

  String get contentType => getItem("contentType");
  String get builder_id => getItem("builder_id");
  String get task_id => getItem("task_id");

  String get after_open => getItem("after_open");
  String get play_sound => getItem("play_sound");
}

class PushResult {
  //出了code以外的其他数据,当code=0的时候有效
  final dynamic result;
  //code = 0 正确
  final int code;

  PushResult({this.code, this.result});

  bool get isOk => code == 0;
}

class UmPushAndroidInfo extends DataItemBase {
  UmPushAndroidInfo(Map data) : super(data);

  String get appKey => getItem("myAppKey");
  String get IMEI => getItem("myImei");
  String get packageName => getItem("myPackageName");
  String get deviceId => getItem("myDeviceId");
  String get version => getItem("myVersion");
  String get toKen => getItem("myToKen");
}

/// 友盟消息推送插件
class FlutterUmPush {
  static const MethodChannel _channel =
      const MethodChannel('flutter_umpush');

  static bool isConnected = false;
  static String registrationID;

  static Future<dynamic> startup() async {
    _channel.setMethodCallHandler(_handler);
    return await _channel.invokeMethod("startup");
  }

  static Future<dynamic> _handler(MethodCall call) {
    print("handle mehtod call ${call.method} ${call.arguments}");
    String method = call.method;
    switch (method) {
      case 'connectionChange':
        {
          isConnected = call.arguments;
          _connectionChangeListener.add(isConnected);
        }
        break;
      case 'networkDidLogin':
        {
          String regId = call.arguments;
          _networkDidLoginListenerListener.add(regId);
        }
        break;
      case 'receivePushMsg':
        {
          _recvCustomMsgController.add(new PushMessage(call.arguments));
        }
        break;
      case 'openNotification':
        {
          _recvOpenNotificationListener
              .add(new PushMessage(call.arguments, true, true));
        }
        break;
      case 'receiveNotification':
        {
          _recvNotificationListener
              .add(new PushMessage(call.arguments, true, false));
        }
        break;
    }
    return new Future.value(null);
  }

  /// 初始化 Push 必须先初始化才能执行其他操作
  static Future<void> initPush() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod("initPush");
    } else {
      FlutterUmPush.setupPush();
    }
  }

  /// 初始化 push SDK 代码 (iOS only), 如果已经在原生 SDK 中添加初始化代码则无需再调用 （通过脚本配置，会自动在原生中添加初始化，无需额外调用）
  static Future<void> setupPush() async {
    await _channel.invokeMethod("setupPush");
  }

  /// 停止推送，调用该方法后将不再受到推送
  static Future<void> stopPush() async {
    await _channel.invokeMethod("stopPush");
  }

  /// 恢复推送功能，停止推送后，可调用该方法重新获得推送能力
  static Future<void> resumePush() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod("resumePush");
    } else {
      FlutterUmPush.setupPush();
    }
  }

  // Android Only
  static Future<void> crashLogOFF() async {
    await _channel.invokeMethod("crashLogOFF");
  }

  // Android Only
  static Future<void> crashLogON() async {
    await _channel.invokeMethod("crashLogON");
  }

  // Android Only
  static Future<void> notifyJSDidLoad() async {
    await _channel.invokeMethod("notifyJSDidLoad");
  }

  /// 清除通知栏的所有通知
  static Future<void> clearAllNotifications() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod("clearAllNotifications");
    } else {
      await FlutterUmPush.setBadge(0);
    }
  }

  // Android Only
  static Future<void> clearNotificationById(int id) async {
    await _channel.invokeMethod("clearNotificationById", id);
  }

  // Android Only
  static Future<UmPushAndroidInfo> getInfo() async {
    Map map = await _channel.invokeMethod("getInfo");
    return new UmPushAndroidInfo(map);
  }

  /// 获取当前连接状态, 如果连接状态变更为已连接返回 true
  static Future<bool> getConnectionState() async {
    return await _channel.invokeMethod("getConnectionState");
  }

  /// 重新设置 Tag
  static Future<PushResult> setTags(List<String> tags) async {
    var raw = await _channel.invokeMethod("setTags", tags);
    return new PushResult(code: raw["errorCode"], result: raw['data']);
  }

  /// 在原有 tags 的基础上添加 tags
  static Future<PushResult> addTags(List<String> tags) async {
    var raw = await _channel.invokeMethod("addTags", tags);
    return new PushResult(code: raw["errorCode"], result: raw['data']);
  }

  /// 删除指定的 tags, 如果成功 result = {tags: [String]}, 如果失败 result = {errorCode: Int}
  static Future<PushResult> deleteTags(List<String> tags) async {
    dynamic raw = await _channel.invokeMethod("deleteTags", tags);
    return new PushResult(code: raw["errorCode"], result: raw['data']);
  }

  /// 清空所有 tags, 如果成功 result = {tags: [String]}, 如果失败 result = {errorCode: Int}
  static Future<PushResult> cleanTags() async {
    var data = await _channel.invokeMethod("cleanTags");
    return new PushResult(
        code: data['errorCode'] as int, result: data['data']);
  }

  /// 获取标签
  static Future<PushResult> getAllTags() async {
    var data = await _channel.invokeMethod("getAllTags");
    return new PushResult(
        code: data['errorCode'] as int, result: data['data']);
  }

  /// 检查当前设备是否绑定该 tag
  static Future<PushResult> checkTagBindState(String tag) async {
    var data = await _channel.invokeMethod("checkTagBindState", tag);
    return new PushResult(
        code: data['errorCode'] as int,
        result: {"tag": data['tag'], "bindState": data['bindState']});
  }

  /// 设置别名
  static Future<PushResult> addAlias(String alias, String aliasType) async {
    var data = await _channel.invokeMethod("addAlias", {"alias": alias, "aliasType": aliasType});
    return new PushResult(
        code: data['errorCode'] as int, result: data['data']);
  }

  /// 设置别名
  static Future<PushResult> setAlias(String alias, String aliasType) async {
    var data = await _channel.invokeMethod("setAlias", {"alias": alias, "aliasType": aliasType});
    return new PushResult(
        code: data['errorCode'] as int, result: data['data']);
  }

  ///  删除别名
  static Future<PushResult> deleteAlias(String alias, String aliasType) async {
    var data = await _channel.invokeMethod("deleteAlias", {"alias": alias, "aliasType": aliasType});
    return new PushResult(
        code: data['errorCode'] as int, result: data['data']);
  }

  // Android Only
  static Future<void> setStyleBasic() async {
    await _channel.invokeMethod("setStyleBasic");
  }

  // Android Only
  static Future<void> setStyleCustom() async {
    await _channel.invokeMethod("setStyleCustom");
  }

  // Android Only
  static Future<void> setLatestNotificationNumber(int maxNumber) async {
    await _channel.invokeMethod("setLatestNotificationNumber", maxNumber);
  }

  /// Android Only. param config = {"startTime": String, "endTime": String}  // 例如：{startTime: "20:30", endTime: "8:30"}
  static Future<void> setSilenceTime(config) async {
    await _channel.invokeMethod("setSilenceTime", config);
  }

  /**
   * Android Only
   * @param {object} config = {"days": Array, "startHour": Number, "endHour": Number}
   * // 例如：{days: [0, 6], startHour: 8, endHour: 23} 表示星期天和星期六的上午 8 点到晚上 11 点都可以推送
   */
  static Future<void> setPushTime(config) async {
    await _channel.invokeMethod("setPushTime", config);
  }

  // Android Only
  static Future<void> jumpToPushActivity(String activityName) async {
    await _channel.invokeMethod("jumpToPushActivity", activityName);
  }

  // Android Only
  static Future<void> jumpToPushActivityWithParams(
      String activityName, Map<String, dynamic> map) async {
    await _channel.invokeMethod("jumpToPushActivityWithParams",
        {"activityName": activityName, map: map});
  }

  // Android Only
  static Future<void> finishActivity() async {
    await _channel.invokeMethod("finishActivity");
  }

  static Map<Function, StreamSubscription> listeners = {};

  /// 监听：自定义消息后事件
  static void addReceiveCustomMsgListener(void onData(PushMessage data)) {
    listeners[onData] = _recvCustomMsgController.stream.listen(onData);
  }

  /// 取消监听：自定义消息后事件
  static void removeReceiveCustomMsgListener(void onData(Map data)) {
    removeListener(onData);
  }

  static void removeListener(void onData(dynamic data)) {
    StreamSubscription listener = listeners[onData];
    if (listener == null) return;
    listener.cancel();
    listeners.remove(onData);
  }

  /**
   * iOS Only
   * 点击推送启动应用的时候原生会将该 notification 缓存起来，该方法用于获取缓存 notification
   * 注意：notification 可能是 remoteNotification 和 localNotification，两种推送字段不一样。
   * 如果不是通过点击推送启动应用，比如点击应用 icon 直接启动应用，notification 会返回 undefine。
   * @param {Function} cb = (notification) => {}
   */
  static getLaunchAppNotification() async {
    await _channel.invokeMethod("getLaunchAppNotification");
  }

  /**
   * @deprecated Since version 2.2.0, will deleted in 3.0.0.
   * iOS Only
   * 监听：应用没有启动的状态点击推送打开应用
   * 注意：2.2.0 版本开始，提供了 getLaunchAppNotification
   *
   * @param {Function} cb = (notification) => {}
   */
  static void addOpenNotificationLaunchAppListener(
      void onData(String registrationId)) {
    listeners[onData] =
        _openNotificationLaunchAppListener.stream.listen(onData);
  }

  /**
   * @deprecated Since version 2.2.0, will deleted in 3.0.0.
   * iOS Only
   * 取消监听：应用没有启动的状态点击推送打开应用
   * @param {Function} cb = () => {}
   */
  static removeOpenNotificationLaunchAppEventListener(
      void onData(String registrationId)) {
    removeListener(onData);
  }

  /**
   * iOS Only
   *
   * 监听：应用连接已登录
   * @param {Function} cb = () => {}
   */
  static void addnetworkDidLoginListener(void onData(String registrationId)) {
    listeners[onData] = _networkDidLoginListenerListener.stream.listen(onData);
  }

  /**
   * iOS Only
   *
   * 取消监听：应用连接已登录
   * @param {Function} cb = () => {}
   */
  static void removenetworkDidLoginListener(
      void onData(String registrationId)) {
    removeListener(onData);
  }

  static StreamController<PushMessage> _recvCustomMsgController =
  new StreamController.broadcast();
  static StreamController<String> _openNotificationLaunchAppListener =
  new StreamController.broadcast();
  static StreamController<String> _networkDidLoginListenerListener =
  new StreamController.broadcast();
  static StreamController<PushMessage> _recvNotificationListener =
  new StreamController.broadcast();
  static StreamController<PushMessage> _recvOpenNotificationListener =
  new StreamController.broadcast();
  static StreamController<String> _getRegistrationIdListener =
  new StreamController.broadcast();
  static StreamController<bool> _connectionChangeListener =
  new StreamController.broadcast();
  static StreamController<Map> _receiveExtrasListener =
  new StreamController.broadcast();

  /**
   * 监听：接收推送事件
   */
  static void addReceiveNotificationListener(
      void onData(PushMessage notification)) {
    listeners[onData] = _recvNotificationListener.stream.listen(onData);
  }

  /**
   * 取消监听：接收推送事件
   * @param {Function} cb = (Object）=> {}
   */
  static void removeReceiveNotificationListener(
      void onData(PushMessage notification)) {
    removeListener(onData);
  }

  /**
   * 监听：点击推送事件
   * @param {Function} cb  = (Object）=> {}
   */
  static void addReceiveOpenNotificationListener(
      void onData(PushMessage notification)) {
    listeners[onData] = _recvOpenNotificationListener.stream.listen(onData);
  }

  /**
   * 取消监听：点击推送事件
   * @param {Function} cb  = (Object）=> {}
   */
  static void removeReceiveOpenNotificationListener(
      void onData(PushMessage notification)) {
    removeListener(onData);
  }

  /**
   * Android Only
   *
   * If device register succeed, the server will return registrationId
   */
  static void addGetRegistrationIdListener(void onData(String registrationId)) {
    listeners[onData] = _getRegistrationIdListener.stream.listen(onData);
  }

  /**
   * Android Only
   */
  static void removeGetRegistrationIdListener(
      void onData(String registrationId)) {
    removeListener(onData);
  }

  /**
   * 监听：连接状态变更
   * @param {Function} cb = (Boolean) => { }
   * 如果连接状态变更为已连接返回 true
   * 如果连接状态变更为断开连接连接返回 false
   */
  static void addConnectionChangeListener(void onData(bool state)) {
    listeners[onData] = _connectionChangeListener.stream.listen(onData);
  }

  /**
   * 监听：连接状态变更
   * @param {Function} cb = (Boolean) => { }
   * 如果连接状态变更为已连接返回 true
   * 如果连接状态变更为断开连接连接返回 false
   */
  static removeConnectionChangeListener(void onData(bool state)) {
    removeListener(onData);
  }

  /**
   * 监听：收到 Native 下发的 extra 事件
   * @param {Function} cb = (map) => { }
   * 返回 Object，属性和值在 Native 定义
   */
  static addReceiveExtrasListener(void onData(Map extra)) {
    listeners[onData] = _receiveExtrasListener.stream.listen(onData);
  }

  static removeReceiveExtrasListener(void onData(Map extra)) {
    removeListener(onData);
  }

  /**
   * 获取 RegistrationId
   * @param {Function} cb = (String) => { }
   */
  static Future<String> getRegistrationID() async {
    return await _channel.invokeMethod("getRegistrationID");
  }

  /**
   * iOS Only
   * @param {Function} cb = (String) => { } // 返回 appKey
   */
  static Future<String> getAppkeyWithcallback() async {
    return await _channel.invokeMethod("getAppkeyWithcallback");
  }

  /**
   * iOS Only
   * @param {Function} cb = (int) => { } // 返回应用 icon badge。
   */
  static Future<int> getBadge() async {
    return await _channel.invokeMethod("getApplicationIconBadge");
  }

  /**
   * iOS Only
   * 设置本地推送
   * @param {Number} date  触发本地推送的时间的时间戳(毫秒)
   * @param {String} textContain 推送消息体内容
   * @param {Int} badge  本地推送触发后 应用 Badge（小红点）显示的数字
   * @param {String} alertAction 弹框的按钮显示的内容（IOS 8默认为"打开", 其他默认为"启动"）
   * @param {String} notificationKey  本地推送标示符
   * @param {Object} userInfo 推送的附加字段 选填
   * @param {String} soundName 自定义通知声音，设置为 null 为默认声音
   */
  static Future<void> setLocalNotification(
      {double date,
        String textContain,
        int badge,
        String alertAction,
        String notificationKey,
        dynamic userInfo,
        String soundName}) async {
    await _channel.invokeMethod("setLocalNotification", {
      "date": date,
      "textContain": textContain,
      "badge": badge,
      "alertAction": alertAction,
      "notificationKey": notificationKey,
      "userInfo": userInfo,
      "soundName": soundName
    });
  }

  /**
   * @typedef Notification
   * @type {object}
   * // Android Only
   * @property {number} [buildId] - 通知样式：1 为基础样式，2 为自定义样式（需先调用 `setStyleCustom` 设置自定义样式）
   * @property {number} [id] - 通知 id, 可用于取消通知
   * @property {string} [title] - 通知标题
   * @property {string} [content] - 通知内容
   * @property {object} [extra] - extra 字段
   * @property {number} [fireTime] - 通知触发时间（毫秒）
   * // iOS Only
   * @property {number} [badge] - 本地推送触发后应用角标值
   * // iOS Only
   * @property {string} [soundName] - 指定推送的音频文件
   * // iOS 10+ Only
   * @property {string} [subtitle] - 子标题
   */

  /**
   * @param {Notification} notification
   */
  static Future<void> sendLocalNotification(
      PushMessage notification) async {
    await _channel.invokeMethod("sendLocalNotification", notification);
  }

  /**
   * iOS Only
   * 设置应用 Badge（小红点）
   * @param {Int} badge
   */
  static Future<void> setBadge(int badge) async {
    await _channel.invokeMethod("setBadge", badge);
  }
}
