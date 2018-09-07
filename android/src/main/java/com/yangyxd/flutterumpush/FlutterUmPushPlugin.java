package com.yangyxd.flutterumpush;

import android.os.Handler;
import android.util.Log;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.util.Map;
import java.util.List;
import java.util.Set;
import java.util.ArrayList;
import java.util.HashMap;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.Notification;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.SparseArray;
import android.widget.Toast;

import com.umeng.commonsdk.UMConfigure;
import com.umeng.message.IUmengCallback;
import com.umeng.message.IUmengRegisterCallback;
import com.umeng.message.MsgConstant;
import com.umeng.message.PushAgent;
import com.umeng.message.UTrack;
import com.umeng.message.UmengMessageHandler;
import com.umeng.message.UmengNotificationClickHandler;
import com.umeng.message.common.inter.ITagManager;
import com.umeng.message.entity.UMessage;
import com.umeng.message.tag.TagManager;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashSet;

import static android.os.Looper.getMainLooper;

/** FlutterUmpushPlugin
 *@author YangYxd
 *@url https://developer.umeng.com/docs/66632/detail/66744
 * */
public class FlutterUmPushPlugin implements MethodCallHandler {
  private MethodChannel channel;
  private Activity activity;

  public FlutterUmPushPlugin(MethodChannel channel, Activity activity) {
    sCacheMap = new SparseArray<>();
    this.channel = channel;
    this.activity = activity;
    _me = this;
    initPush();
  }

  private static FlutterUmPushPlugin _me;

  private static FlutterUmPushPlugin me() {
    return _me;
  }

  private Activity getCurrentActivity() {
    return activity;
  }

  private Context getApplicationContext() {
    return activity == null ? null : activity.getApplicationContext();
  }


  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_umpush");
    Log.d(TAG, "register umpush plugin");

    channel.setMethodCallHandler(new FlutterUmPushPlugin(
            channel, registrar.activity()
    ));

    FlutterUmPushPlugin.mRAC = registrar.activity();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    String method = call.method;
    if ("initPush".equals(method)) {
      this.initPush();
      result.success(true);
    }else if ("startup".equals(method)) {
      this.startup();
      result.success(true);
    } else if ("getInfo".equals(method)) {
      this.getInfo(result);
    } else if ("stopPush".equals(method)) {
      this.stopPush();
      result.success(true);
    } else if ("resumePush".equals(method)) {
      this.resumePush();
      result.success(true);
    } else if ("crashLogOFF".equals(method)) {
      this.crashLogOFF();
      result.success(true);
    } else if ("crashLogON".equals(method)) {
      this.crashLogON();
      result.success(true);
    } else if ("setTags".equals(method)) {
      result.notImplemented();
    } else if ("addTags".equals(method)) {
      this.addTags((List) call.arguments, result);
    } else if ("deleteTags".equals(method)) {
      this.deleteTags((List) call.arguments, result);
    } else if ("cleanTags".equals(method)) {
      this.cleanTags(result);
    } else if ("getAllTags".equals(method)) {
      this.getAllTags(result);
    } else if ("checkTagBindState".equals(method)) {
      this.checkTagBindState((String) call.arguments, result);
    } else if ("addAlias".equals(method)) {
      Map map = (Map) call.arguments;
      this.addAlias((String) map.get("alias"), (String) map.get("aliasType"), result);
    } else if ("setAlias".equals(method)) {
      Map map = (Map) call.arguments;
      this.setAlias((String) map.get("alias"), (String) map.get("aliasType"), result);
    } else if ("deleteAlias".equals(method)) {
      Map map = (Map) call.arguments;
      this.deleteAlias((String) map.get("alias"), (String) map.get("aliasType"), result);
    } else if ("getAlias".equals(method)) {
      this.getAlias(result);
    } else if ("getRegistrationID".equals(method)) {
      this.getRegistrationID(result);
    } else if ("getConnectionState".equals(method)) {
      this.getConnectionState(result);
    } else if ("clearAllNotifications".equals(method)) {
      this.clearAllNotifications();
      result.success(true);
    } else if ("clearNotificationById".equals(method)) {
      this.clearNotificationById((Integer) call.arguments);
      result.success(true);
    } else if ("setLatestNotificationNumber".equals(method)) {
      this.setLatestNotificationNumber((Integer) call.arguments);
      result.success(true);
    } else if ("setSilenceTime".equals(method)) {
      this.setSilenceTime((Map) call.arguments);
      result.success(true);
    } else if ("setResourcePackageName".equals(method)) {
      this.setResourcePackageName((Map) call.arguments);
      result.success(true);
    } else if ("sendLocalNotification".equals(method)) {
      this.sendLocalNotification((Map) call.arguments);
      result.success(true);
    } else if ("jumpToPushActivity".equals(method)) {
      this.jumpToPushActivity((String) call.arguments);
      result.success(true);
    } else if ("jumpToPushActivityWithParams".equals(method)) {
      Map map = (Map) call.arguments;
      this.jumpToPushActivityWithParams((String) map.get("activityName"), (Map) map.get("map"));
      result.success(true);
    } else if ("finishActivity".equals(method)) {
      this.finishActivity();
      result.success(true);
    } else if ("dispose".equals(method)) {
      this.dispose();
      result.success(true);
    } else {
      result.notImplemented();
    }
  }


  private static String TAG = "FlutterUmPushPlugin";
  private Context mContext;
  private static String mEvent;
  private static UMessage mMsg;
  private static Activity mRAC;

  private final static String RECEIVE_NOTIFICATION = "receiveNotification";
  private final static String RECEIVE_CUSTOM_MESSAGE = "receivePushMsg";
  private final static String OPEN_NOTIFICATION = "openNotification";
  private final static String RECEIVE_REGISTRATION_ID = "getRegistrationId";
  private final static String CONNECTION_CHANGE = "connectionChange";

  private static SparseArray<Result> sCacheMap;
  private static Result mGetRidResult;


  public void dispose() {
    mMsg = null;
    if (null != sCacheMap) {
      sCacheMap.clear();
    }
    mEvent = null;
    mGetRidResult = null;
  }


  public void initPush() {
    PushAgent.getInstance(getCurrentActivity()).onAppStart();
    Logger.i(TAG, "init Success!");
  }

  public void startup() {
    mContext = getCurrentActivity();
    initUpush(getApplicationContext(), PushAgent.getInstance(mContext));
    Logger.i(TAG, "init Push Success!");
  }

  public void getInfo(Result successResult) {
    Map map = new HashMap();
    String appKey = "AppKey:" + ExampleUtil.getAppKey(getApplicationContext());
    map.put("myAppKey", appKey);
    String imei = "IMEI: " + ExampleUtil.getImei(getApplicationContext(), "");
    map.put("myImei", imei);
    String packageName = "PackageName: " + getApplicationContext().getPackageName();
    map.put("myPackageName", packageName);
    String deviceId = "DeviceId: " + ExampleUtil.getDeviceId(getApplicationContext());
    map.put("myDeviceId", deviceId);
    String version = "Version: " + ExampleUtil.GetVersion(getApplicationContext());
    map.put("myVersion", version);
    String toKen = "ToKen: " + ExampleUtil.GetVersion(getApplicationContext());
    map.put("myToKen", toKen);
    successResult.success(map);
  }

  public void stopPush() {
    mContext = getCurrentActivity();
    PushAgent.getInstance(mContext).disable(
            new IUmengCallback() {
              @Override
              public void onSuccess() {
                Logger.toast(mContext, "Stop push success");
              }
              @Override
              public void onFailure(String s, String s1) {
                Logger.i(TAG, String.format("UMPush disable Failure. %s, %s", s, s1));
              }
            }
    );
    Logger.i(TAG, "Stop push");
  }

  public void resumePush() {
    mContext = getCurrentActivity();
    PushAgent.getInstance(mContext).enable(
          new IUmengCallback() {
            @Override
            public void onSuccess() {
              Logger.toast(mContext, "Resume push success");
            }

            @Override
            public void onFailure(String s, String s1) {
              Logger.i(TAG, String.format("UMPush enable Failure. %s, %s", s, s1));
            }
          }
    );
    Logger.i(TAG, "Resume push");
  }

  public void crashLogOFF() {
    UMConfigure.setLogEnabled(false);
  }


  public void crashLogON() {
    UMConfigure.setLogEnabled(true);
  }


  void sendEvent() {
    if (mEvent != null) {
      Logger.i(TAG, "Sending event : " + mEvent);
      switch (mEvent) {
        case RECEIVE_CUSTOM_MESSAGE:
          Map map = new HashMap();
          map.put("id", mMsg.message_id);
          map.put("message", mMsg.text);
          map.put("custom", mMsg.custom);
          map.put("img", mMsg.img);
          map.put("icon", mMsg.icon);
          map.put("largeIcon", mMsg.largeIcon);
          map.put("title",mMsg.title);
          map.put("ticker", mMsg.ticker);
          map.put("contentType",mMsg.display_type);
          map.put("extras", mMsg.extra);
          map.put("activity", mMsg.activity);
          map.put("builder_id", mMsg.builder_id); // 自定义通知样式, 默认为0
          map.put("task_id", mMsg.task_id);
          map.put("after_open", mMsg.after_open);
          map.put("play_sound", mMsg.play_sound);
          channel.invokeMethod("receivePushMsg", map);
          break;
        case RECEIVE_REGISTRATION_ID:
          if (mGetRidResult != null) {
            mGetRidResult.success((String) ExampleUtil.token);
            mGetRidResult = null;
          }
          channel.invokeMethod("networkDidLogin", (String) ExampleUtil.token);
          break;
        case RECEIVE_NOTIFICATION:
        case OPEN_NOTIFICATION:
          map = new HashMap();
          map.put("id", mMsg.msg_id);
          map.put("message", mMsg.text);
          map.put("img", mMsg.img);
          map.put("icon", mMsg.icon);
          map.put("largeIcon", mMsg.largeIcon);
          map.put("title",mMsg.title);
          map.put("ticker", mMsg.ticker);
          map.put("url", mMsg.url);
          map.put("alerType",mMsg.display_type);
          map.put("extras", mMsg.extra);
          map.put("activity", mMsg.activity);
          map.put("builder_id", mMsg.builder_id);
          map.put("task_id", mMsg.task_id);
          map.put("after_open", mMsg.after_open);
          map.put("play_sound", mMsg.play_sound);
          channel.invokeMethod(mEvent == OPEN_NOTIFICATION ? "openNotification" : "receiveNotification", map);
          break;
        case CONNECTION_CHANGE:
          channel.invokeMethod("connectionChange", ExampleUtil.token != null && ExampleUtil.token.length() > 0);
          break;
      }
      mEvent = null;
      mMsg = null;
    }
  }

  private int getSequence() {
    SimpleDateFormat sdf = new SimpleDateFormat("MMddHHmmss");
    String date = sdf.format(new Date());
    return Integer.valueOf(date);
  }

  private String[] getStringArrary(List list) {
    String[] v = new String[list.size()];
    for (int i=0; i<list.size(); i++) {
      v[i] = list.get(i).toString();
    }
    return v;
  }

  /** 返回数据 */
  class PushResult extends HashMap {
    PushResult(int code, Object result) {
      this.put("errorCode", code);
      this.put("data", result == null ? "" : result);
    }
  }

  public void addTags(final List tags, Result result) {
    final int sequence = getSequence();
    Logger.i(TAG, "tags to be added: " + tags.toString() + " sequence: " + sequence);
    sCacheMap.put(sequence, result);
    PushAgent.getInstance(getCurrentActivity()).getTagManager().addTags(new TagManager.TCallBack() {
      @Override
      public void onMessage(boolean isSuccess, ITagManager.Result result) {
        if (isSuccess)
          sCacheMap.get(sequence).success(new PushResult(0, tags));
        else
          sCacheMap.get(sequence).success(new PushResult(-1, result.jsonString));
        sCacheMap.delete(sequence);
      }
    }, getStringArrary(tags));
  }

  public void deleteTags(final List tags, Result result) {
    final int sequence = getSequence();
    Logger.i(TAG, "tags to be deleted: " + tags.toString() + " sequence: " + sequence);
    sCacheMap.put(sequence, result);
    PushAgent.getInstance(getCurrentActivity()).getTagManager().deleteTags(new TagManager.TCallBack() {
      @Override
      public void onMessage(boolean isSuccess, ITagManager.Result result) {
        if (isSuccess)
          sCacheMap.get(sequence).success(new PushResult(0, tags));
        else
          sCacheMap.get(sequence).success(new PushResult(-1, result.jsonString));
        sCacheMap.delete(sequence);
      }
    }, getStringArrary(tags));
  }

  public void cleanTags(Result result) {
    result.notImplemented();
  }

  public void getAllTags(Result result) {
    final int sequence = getSequence();
    sCacheMap.put(sequence, result);
    Logger.i(TAG, "Get all tags, sequence: " + sequence);

    PushAgent.getInstance(getCurrentActivity()).getTagManager().getTags(new TagManager.TagListCallBack() {
      @Override
      public void onMessage(boolean isSuccess, List<String> list) {
        if (isSuccess)
          sCacheMap.get(sequence).success(new PushResult(0, list));
        else
          sCacheMap.get(sequence).success(new PushResult(-1, null));
        sCacheMap.delete(sequence);
      }
    });
  }

  public void checkTagBindState(String tag, Result result) {
    result.notImplemented();
  }

  public void addAlias(String alias, String aliasType, Result result) {
    final int sequence = getSequence();
    Logger.i(TAG, "Add alias, sequence: " + sequence);
    sCacheMap.put(sequence, result);
    PushAgent.getInstance(getCurrentActivity()).addAlias(alias, aliasType, new UTrack.ICallBack() {
      @Override
      public void onMessage(boolean isSuccess, String s) {
        sCacheMap.get(sequence).success(new PushResult(isSuccess ? 0 : -1, s));
        sCacheMap.delete(sequence);
      }
    });
  }

  public void setAlias(String alias, String aliasType, Result result) {
    final int sequence = getSequence();
    Logger.i(TAG, "Set alias, sequence: " + sequence);
    sCacheMap.put(sequence, result);
    PushAgent.getInstance(getCurrentActivity()).setAlias(alias, aliasType, new UTrack.ICallBack() {
      @Override
      public void onMessage(boolean isSuccess, String s) {
        sCacheMap.get(sequence).success(new PushResult(isSuccess ? 0 : -1, s));
        sCacheMap.delete(sequence);
      }
    });
  }

  public void deleteAlias(String alias, String aliasType, Result result) {
    final int sequence = getSequence();
    Logger.i(TAG, "Delete alias, sequence: " + sequence);
    sCacheMap.put(sequence, result);
    PushAgent.getInstance(getCurrentActivity()).deleteAlias(alias, aliasType, new UTrack.ICallBack() {
      @Override
      public void onMessage(boolean isSuccess, String s) {
        sCacheMap.get(sequence).success(new PushResult(isSuccess ? 0 : -1, s));
        sCacheMap.delete(sequence);
      }
    });
  }

  public void getAlias(Result result) {
    result.notImplemented();
  }

  public void getRegistrationID(Result result) {
    try {
      String id = ExampleUtil.token;
      if (id != null) {
        result.success(id);
      } else {
        mGetRidResult = result;
      }
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }


  public void getConnectionState(Result result) {
    result.success(ExampleUtil.token != null && !ExampleUtil.token.isEmpty());
  }

  public void clearAllNotifications() {

  }

  /**
   * Clear specified notification
   *
   * @param id the notification id
   */

  public void clearNotificationById(int id) {
    try {
      mContext = getCurrentActivity();
      // 未实现
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }


  public void setLatestNotificationNumber(int number) {
    try {
      mContext = getCurrentActivity();
      PushAgent.getInstance(getCurrentActivity()).setDisplayNotificationNumber(number);
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }

  public void setSilenceTime(Map map) {
      try {
          mContext = getCurrentActivity();
          List array = (List) map.get("days");
          Set<Integer> days = new HashSet<Integer>();
          for (int i = 0; i < array.size(); i++) {
              days.add((Integer) array.get(i));
          }
          int startHour = (Integer) map.get("startHour");
          int endHour = (Integer) map.get("endHour");
          PushAgent.getInstance(getCurrentActivity()).setNoDisturbMode(startHour, 0, endHour, 0);
      } catch (Throwable e) {
          e.printStackTrace();
      }
  }

  public void setResourcePackageName(Map map) {
    try {
      mContext = getCurrentActivity();
      String packageName = (String) map.get("packageName");
      PushAgent.getInstance(mContext).setResourcePackageName(packageName);
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }

  public void sendLocalNotification(Map map) {
    try {

    } catch (Throwable e) {
      e.printStackTrace();
    }
  }

  /** 发送事件 */
  private static void sendEventNotify(String aEvent) {
    try {
      mEvent = aEvent;
      if (mRAC != null) {
        FlutterUmPushPlugin.me().sendEvent();
      }
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }

  private static Handler handler = new Handler(getMainLooper());

  /** 初始化推送 */
  public static void initUpush(final Context appcontext, PushAgent mPushAgent) {
    //sdk开启通知声音
    mPushAgent.setNotificationPlaySound(MsgConstant.NOTIFICATION_PLAY_SDK_ENABLE);

    // 通知的回调方法（通知送达时会回调）
    UmengMessageHandler messageHandler = new UmengMessageHandler() {
      @Override
      public void dealWithNotificationMessage(Context context, UMessage msg) {
        //调用super，会展示通知，不调用super，则不展示通知。
        mMsg = msg;
        try {
          if(!Logger.SHUTDOWNLOG){
            Logger.i(TAG, "收到推送下来的通知: " + msg.custom);
            Logger.i(TAG, "extras: " + msg.extra.toString());
          }
          sendEventNotify(RECEIVE_NOTIFICATION);
        } catch (Throwable e) {
          e.printStackTrace();
        }
        super.dealWithNotificationMessage(context, msg);
      }

      /** 自定义消息的回调方法  */
      @Override
      public void dealWithCustomMessage(final Context context, final UMessage msg) {
        handler.post(new Runnable() {

          @Override
          public void run() {
            // 对自定义消息的处理方式，点击或者忽略
            mMsg = msg;
            try {
              if(!Logger.SHUTDOWNLOG){
                Logger.i(TAG, "收到自定义消息: " + mMsg.custom);
              }
              sendEventNotify(RECEIVE_CUSTOM_MESSAGE);
              if (mRAC == null) {
                //自定义消息的忽略统计
                UTrack.getInstance(appcontext).trackMsgDismissed(msg);
                // UTrack.getInstance(appcontext).trackMsgClick(msg);
              }
            } catch (Throwable e) {
              e.printStackTrace();
            }
          }
        });
      }

      /** 自定义通知栏样式的回调方法 */
      @Override
      public Notification getNotification(Context context, UMessage msg) {
        return super.getNotification(context, msg);
      }
    };
    mPushAgent.setMessageHandler(messageHandler);

    /**
     * 自定义行为的回调处理，参考文档：高级功能-通知的展示及提醒-自定义通知打开动作
     * UmengNotificationClickHandler是在BroadcastReceiver中被调用，故
     * 如果需启动Activity，需添加Intent.FLAG_ACTIVITY_NEW_TASK
     * */
    UmengNotificationClickHandler notificationClickHandler = new UmengNotificationClickHandler() {
      @Override
      public void launchApp(Context context, UMessage msg) {
        super.launchApp(context, msg);
      }
      @Override
      public void openUrl(Context context, UMessage msg) {
        super.openUrl(context, msg);
      }
      @Override
      public void openActivity(Context context, UMessage msg) {
        super.openActivity(context, msg);
      }
      @Override
      public void dealWithCustomAction(Context context, UMessage msg) {
        Toast.makeText(context, msg.custom, Toast.LENGTH_SHORT).show();
      }
    };
    //使用自定义的NotificationHandler
    mPushAgent.setNotificationClickHandler(notificationClickHandler);

    //注册推送服务 每次调用register都会回调该接口
    mPushAgent.register(new IUmengRegisterCallback() {
      @Override
      public void onSuccess(String deviceToken) {
        ExampleUtil.token = deviceToken;
        Logger.i(TAG, "device token: " + deviceToken);
        sendEventNotify(CONNECTION_CHANGE);
        sendEventNotify(RECEIVE_REGISTRATION_ID);
      }

      @Override
      public void onFailure(String s, String s1) {
        ExampleUtil.token = null;
        sendEventNotify(CONNECTION_CHANGE);
        Logger.i(TAG, "register failed: " + s + " " + s1);
      }
    });

    //使用完全自定义处理
    //mPushAgent.setPushIntentServiceClass(UmengNotificationService.class);

    //小米通道
    //MiPushRegistar.register(this, XIAOMI_ID, XIAOMI_KEY);
    //华为通道
    //HuaWeiRegister.register(this);
    //魅族通道
    //MeizuRegister.register(this, MEIZU_APPID, MEIZU_APPKEY);
  }

  private static boolean isApplicationRunningBackground(final Context context) {
    ActivityManager am = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
    List<ActivityManager.RunningTaskInfo> tasks = am.getRunningTasks(1);
    if (!tasks.isEmpty()) {
      ComponentName topActivity = tasks.get(0).topActivity;
      if (!topActivity.getPackageName().equals(context.getPackageName())) {
        return true;
      }
    }
    return false;
  }


  public void jumpToPushActivity(String activityName) {
    Logger.d(TAG, "Jumping to " + activityName);
    try {
      Intent intent = new Intent();
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      intent.setClassName(mRAC, mRAC.getPackageName() + "." + activityName);
      mRAC.startActivity(intent);

    } catch (Throwable e) {
      e.printStackTrace();
    }
  }


  public void jumpToPushActivityWithParams(String activityName, Map map) {
    Logger.d(TAG, "Jumping to " + activityName);
    try {
      Intent intent = new Intent();
      if (null != map) {
        map2intent(map, intent);
      }
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
      intent.setClassName(mRAC, mRAC.getPackageName() + "." + activityName);
      mRAC.startActivity(intent);
    } catch (Throwable e) {
      e.printStackTrace();
    }
  }

  private void map2intent(Map<String, Object> map, JSONObject intent) throws JSONException {
    for (java.util.Map.Entry<String, Object> entity : map.entrySet()) {
      intent.put(entity.getKey(), String.valueOf(entity.getValue()));
    }
  }

  private void map2intent(Map<String, Object> map, Intent intent) {
    for (java.util.Map.Entry<String, Object> entity : map.entrySet()) {
      intent.putExtra(entity.getKey(), String.valueOf(entity.getValue()));
    }
  }


  public void finishActivity() {
    try {
      Activity activity = getCurrentActivity();
      activity.finish();
    } catch (Throwable e) {
      e.printStackTrace();
    }

  }

}
