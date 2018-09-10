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

#### 申请key

## 申请key

进入[这里](http://message.umeng.com/list/new/app)创建或添加已有应用。然后可以在应用信息中看到 Appkey、Umeng Message Secret
同时在应用信息中可以设置包名为你的app包名。
详细信息参考开发文档(https://developer.umeng.com/?refer=UPush)

#### ios 证书申请

同安卓一样进入（http://message.umeng.com/list/apps）新建应用。
详情参考iOS开发文档(https://developer.umeng.com/docs/66632/detail/66734)

### ios 集成


## android 集成

1. 将下载回来SDK中（或本项目example）的 push 文件夹复制到你项目的 android 目录中。
2. 在 push 的 libs 中将缺少的so、jar补全，参考下图
![image](https://github.com/yangyxd/flutter_umpush/blob/master/raw/img001.png)
