<center>
<h1>CloudBrowser</h1>

A Wonderful WebDAV client application

![Flutter](https://img.shields.io/badge/flutter-%2302569B.svg?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white) ![License](https://img.shields.io/badge/License-GPLv3-blue)

**English** | [**中文简体**](./docs/cn/README.md) 

</center>


---

## Preview
<center>
<figure>
<img src=docs/images/Home_light.jpg width=256/>
&ensp;
<img src=docs/images/Home_dark.jpg width=256/>
</figure>
</center>

## Project Status
- [x] Configuration File Management (Add/Edit/Delete)
- [x] Breadcrumb Navigation System
- [x] Animation Interaction Experience
- [ ] WebDAV Operation Functions (Upload/Download/Move/Copy)
- [x] Android Client Function Verification
- [ ] Multi-platform Adaptation Verification (Basic support already implemented)

## Key Features
- 🔐 Secure Configuration Management
  - Supports multiple account configurations (Protocol/Address/Port/Authentication)
  - JSON format persistent storage (Path: `${getApplicationSupportDirectory()}/conf.d/*.json`)
- 📄 Smart File Display
  - Real-time remote file list loading
- 🧭 Intelligent Navigation System
  - Dynamic path tracking generation
  - Quick return to historical directories
- 🎨 Interaction Optimization
  - Material Design 3 style
  - Smooth animation transitions
  - Adaptive theme mode (follows system dark/light mode)

## Development Dependencies
- [webdav_client](https://pub.dev/packages/webdav_client)
- [path_provider](https://pub.dev/packages/path_provider)

## Quick Start Guide
1. **Initial Configuration**
   - Click "Add New Configuration" or create WebDAV connection through sidebar
   - At least one configuration is required to access file system

2. **Multi-account Management**
   - Supports creating multiple configuration profiles
   - Click configuration item to switch accounts
   - Edit/Delete operations available

3. **File Operations**
   - Main interface displays current directory file list
   - Click breadcrumb navigation to quickly access other directories

4. **Build & Deployment**
```bash
flutter build [windows|macos|linux|ios|apk|web]
```

## License
This project uses the [GNU General PublicLicense v3.0](LICENSE.txt) open source license.

## Contributing
Welcome to contribute code, report issues, or submit suggestions.