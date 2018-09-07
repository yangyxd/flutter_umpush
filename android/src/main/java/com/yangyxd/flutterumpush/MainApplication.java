package com.yangyxd.flutterumpush;

import android.app.ActivityManager;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Handler;

import com.umeng.commonsdk.UMConfigure;
import com.umeng.message.PushAgent;

import java.util.List;
import io.flutter.app.FlutterApplication;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        try {
            init(this.getApplicationContext());
        } catch (Exception e) {
            e.printStackTrace();
        }
   }

    public static void init(Context context) {
        UMConfigure.setLogEnabled(true);
        UMConfigure.init(context, null, null, UMConfigure.DEVICE_TYPE_PHONE, null);
        FlutterUmPushPlugin.initUpush(context, PushAgent.getInstance(context));
    }

//    private boolean shouldInit() {
//
//        //通过ActivityManager我们可以获得系统里正在运行的activities
//        //包括进程(Process)等、应用程序/包、服务(Service)、任务(Task)信息。
//        ActivityManager am = ((ActivityManager) getSystemService(Context.ACTIVITY_SERVICE));
//        List<ActivityManager.RunningAppProcessInfo> processInfos = am.getRunningAppProcesses();
//        String mainProcessName = getPackageName();
//
//        //获取本App的唯一标识
//        int myPid = android.os.Process.myPid();
//        //利用一个增强for循环取出手机里的所有进程
//        for (ActivityManager.RunningAppProcessInfo info : processInfos) {
//            //通过比较进程的唯一标识和包名判断进程里是否存在该App
//            if (info.pid == myPid && mainProcessName.equals(info.processName)) {
//                return true;
//            }
//        }
//        return false;
//    }
//
//    public static String getMetaData(Context context, String name) {
//        try {
//            ApplicationInfo appInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(),
//                    PackageManager.GET_META_DATA);
//            return appInfo.metaData.getString("name");
//        } catch (PackageManager.NameNotFoundException e) {
//            return null;
//        }
//    }
}
