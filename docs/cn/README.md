<center>
<h1>CloudBrowser</h1>

一个功能强大的 WebDAV 客户端

![Flutter](https://img.shields.io/badge/flutter-%2302569B.svg?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white) ![License](https://img.shields.io/badge/License-GPLv3-blue)

[**English**](/README.md) | **中文简体**

</center>

---

## 预览
<center>
<figure>
<img src=/docs/images/Home_light.jpg width=256/>
&ensp;
<img src=/docs/images/Home_dark.jpg width=256/>
</figure>
</center>

## 项目状态
- [x] 配置文件管理（添加、编辑、删除）
- [x] 面包屑导航系统
- [x] 动画交互体验
- [ ] WebDAV操作功能（上传、下载、移动、复制）
- [x] Android 客户端功能验证
- [ ] 多平台适配验证（当前已实现基础支持）

## 功能亮点
- 🔐 安全配置管理
  - 支持多账户配置（协议/地址/端口/认证信息）
  - JSON格式持久化存储（路径：`${getApplicationSupportDirectory()}/conf.d/*.json`）
- 📄 智能文件展示
  - 实时加载远程文件列表
- 🧭 智能导航系统
  - 动态生成路径追踪
  - 支持快速返回历史目录
- 🎨 交互优化
  - Material Design 3 风格
  - 流畅的动画过渡效果
  - 自适应主题模式（跟随系统深色/浅色模式）

## 开发依赖
- [webdav_client](https://pub.dev/packages/webdav_client)
- [path_provider](https://pub.dev/packages/path_provider)

## 快速使用指南
1. **初始配置**
   - 点击"添加新配置"或通过侧边栏创建WebDAV连接
   - 需要至少一个配置才能访问文件系统

2. **多账户管理**
   - 支持创建多个配置文件
   - 单击配置项即可切换配置
   - 可进行编辑/删除操作

3. **文件操作**
   - 主界面显示当前目录文件列表
   - 点击面包屑导航可快速访问其他目录

4. **构建部署**
```bash
flutter build [windows|macos|linux|ios|apk|web]
```

## 许可证
本项目采用[GPLv3](LICENSE.txt)开源许可证。

## 贡献
欢迎贡献代码、提出问题或提出建议。