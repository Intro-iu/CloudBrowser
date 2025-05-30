import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../services/webdav_service.dart';
import '../models/webdav_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late WebDAVService _webdavService;
  var _dirPath = '/';

  bool _isFromBreadcrumb = false; // 新增标志位
  List<String> _breadcrumbParts = [];
  final ScrollController _breadcrumbScrollController = ScrollController();
  final GlobalKey _currentBreadcrumbKey = GlobalKey();

  final SliverOverlapAbsorberHandle _overlapHandle =
      SliverOverlapAbsorberHandle();
  final GlobalKey _sliverAppBarKey =
      GlobalKey(); // 用于获取 SliverAppBar 的 RenderObject

  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<webdav.File> _files = [];
  String? _errorMessage;

  final String _mainConfigFile = 'config.json'; // 主配置文件
  WebDAVConfig? _currentConfig; // 当前配置

  final String _configDir = 'conf.d'; // 配置目录
  List<WebDAVConfig> _configs = []; // 配置列表

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadConfigs().then((configs) {
      setState(() {
        _configs = configs;
        if (_configs.isNotEmpty) {
          _loadCurrentConfig().then((config) {
            setState(() {
              _currentConfig = config;
              _initializeWebDAV();
            });
          });
        } else {
          // 新增空配置状态
          _currentConfig = null;
          _isLoading = false;
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _breadcrumbScrollController.dispose();
    _animationController.dispose();
  }

  void _initializeWebDAV() {
    if (_currentConfig != null) {
      _webdavService = WebDAVService(
        url: _currentConfig!.fullUrl,
        username: _currentConfig!.username,
        password: _currentConfig!.password,
      );
      _loadFiles();
    }
  }

  // 加载所有配置文件
  Future<List<WebDAVConfig>> _loadConfigs() async {
    try {
      final appDocDir = await getApplicationSupportDirectory();
      final configDir = Directory('${appDocDir.path}/$_configDir');

      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
        return [];
      }

      final configFiles =
          configDir
              .listSync()
              .where(
                (entity) => entity is File && entity.path.endsWith('.json'),
              )
              .map((entity) => File(entity.path))
              .toList();

      final configs = <WebDAVConfig>[];
      for (final file in configFiles) {
        final configJson = jsonDecode(file.readAsStringSync());
        final configName = file.path.split('/').last.replaceAll('.json', '');
        configs.add(WebDAVConfig.fromJson(configName, configJson));
      }

      return configs;
    } catch (e) {
      return [];
    }
  }

  // 加载当前配置
  Future<WebDAVConfig?> _loadCurrentConfig() async {
    final appDocDir = await getApplicationSupportDirectory();
    final mainConfigFile = File('${appDocDir.path}/$_mainConfigFile');

    if (!mainConfigFile.existsSync()) {
      return _configs.isNotEmpty ? _configs.first : null;
    }

    final configName =
        jsonDecode(mainConfigFile.readAsStringSync())['current_config'];
    return _configs.firstWhere((config) => config.name == configName);
  }

  // 保存当前配置
  Future<void> _saveCurrentConfig(String configName) async {
    final appDocDir = await getApplicationSupportDirectory();
    final mainConfigFile = File('${appDocDir.path}/$_mainConfigFile');
    mainConfigFile.writeAsString(jsonEncode({'current_config': configName}));
  }

  // 保存配置文件
  Future<void> _saveConfig(WebDAVConfig config) async {
    final appDocDir = await getApplicationSupportDirectory();
    final configDir = Directory('${appDocDir.path}/$_configDir');
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }

    final configFile = File('${configDir.path}/${config.name}.json');
    configFile.writeAsStringSync(jsonEncode(config.toJson())); // 使用模型的toJson方法
  }

  // 显示配置对话框
  void _showConfigDialog({WebDAVConfig? existingConfig}) {
    final isEditing = existingConfig != null;
    final nameController = TextEditingController(text: existingConfig?.name);
    final protocolController = TextEditingController(
      text: existingConfig?.protocol ?? 'https',
    );
    final addressController = TextEditingController(
      text: existingConfig?.address,
    );
    final portController = TextEditingController(
      text: existingConfig?.port.toString(),
    );
    final userController = TextEditingController(
      text: existingConfig?.username,
    );
    final pwdController = TextEditingController(text: existingConfig?.password);
    final pathController = TextEditingController(text: existingConfig?.path);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? '编辑配置: ${existingConfig.name}' : '添加新配置'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: '配置名称',
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      enabled: !isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '配置名称不能为空';
                        }
                        if (!isEditing &&
                            _configs.any((c) => c.name == value)) {
                          return '配置名称已存在';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: addressController,
                            decoration: InputDecoration(
                              labelText: '地址',
                              errorStyle: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '地址不能为空';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: portController,
                            decoration: InputDecoration(
                              labelText: '端口',
                              errorStyle: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '端口不能为空';
                              }
                              if (int.tryParse(value) == null) {
                                return '请输入有效端口';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: protocolController.text,
                      items:
                          ['http', 'https'].map((protocol) {
                            return DropdownMenuItem(
                              value: protocol,
                              child: Text(protocol.toUpperCase()),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          protocolController.text = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: '协议',
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请选择协议';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: '用户名',
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '用户名不能为空';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: pwdController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        // 新增验证器
                        if (value == null || value.isEmpty) {
                          return '密码不能为空';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: pathController,
                      decoration: InputDecoration(
                        labelText: '路径',
                        errorStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '路径不能为空';
                        }
                        if (!value.startsWith('/')) {
                          return '路径必须以斜杠开头';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final newConfig = WebDAVConfig(
                      name: nameController.text,
                      protocol: protocolController.text,
                      address: addressController.text,
                      port: int.parse(portController.text),
                      username: userController.text,
                      password: pwdController.text,
                      path: pathController.text,
                    );

                    _saveConfig(newConfig).then((_) {
                      setState(() {
                        if (isEditing) {
                          final index = _configs.indexWhere(
                            (c) => c.name == existingConfig.name,
                          );
                          _configs[index] = newConfig;
                        } else {
                          _configs.add(newConfig);
                        }
                        _saveCurrentConfig(newConfig.name);
                        _currentConfig = newConfig;
                        _dirPath = '/';
                        _initializeWebDAV();
                        Navigator.of(context).pop();
                      });
                    });
                  }
                },
                child: Text(isEditing ? '更新' : '添加'),
              ),
            ],
          ),
    );
  }

  // 加载目录内容
  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final files = await _webdavService.readDirectory(_dirPath);
      setState(() {
        _files = files;
        _isLoading = false;
        _animationController.reset(); // 重置动画
        _animationController.forward(); // 启动动画
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '无法加载目录: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isFromBreadcrumb = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scrollController = PrimaryScrollController.of(context);
        if (!scrollController.hasClients) return;
      });
    }
  }

  // 解析路径
  String _buildPath(String fileName) {
    // 统一路径格式：始终在末尾添加斜杠
    final cleanPath = _dirPath.replaceAll(RegExp(r'/+'), '/');
    return cleanPath.endsWith('/')
        ? '$cleanPath$fileName/'
        : '$cleanPath/$fileName/';
  }

  // 返回键
  void _goToParentDirectory() {
    if (_dirPath != '/') {
      setState(() {
        final cleanPath =
            _dirPath.endsWith('/')
                ? _dirPath.substring(0, _dirPath.length - 1)
                : _dirPath;
        final newPath = cleanPath.substring(0, cleanPath.lastIndexOf('/') + 1);
        _dirPath = newPath.isEmpty ? '/' : newPath;
        _isFromBreadcrumb = true; // 标记为面包屑操作以跳过更新
      });
      _triggerBreadcrumbScroll(); // 新增滚动触发
      _loadFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是根目录'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  // 主页载体
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: _sliverBuilder,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            _goToParentDirectory();
            return;
          },
          child: _buildBodyContent(),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(height: kToolbarHeight),

            // 配置列表
            for (final config in _configs)
              ListTile(
                title: Text(config.name),
                trailing: Row(
                  // 修改为Row包含两个按钮
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed:
                          () => _showConfigDialog(existingConfig: config),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteConfig(config),
                      tooltip: '删除配置',
                    ),
                  ],
                ),
                selected: _currentConfig?.name == config.name,
                onTap: () {
                  setState(() {
                    _currentConfig = config;
                    _dirPath = '/';
                    _breadcrumbParts = []; // 清空面包屑部件
                    _saveCurrentConfig(config.name);
                    _initializeWebDAV();
                    _rebuildBreadcrumb(); // 新增面包屑重建方法
                  });
                },
              ),

            // 添加配置项
            ListTile(
              title: Text('添加新配置'),
              leading: Icon(Icons.add),
              onTap: () => _showConfigDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // 删除配置方法
  void _deleteConfig(WebDAVConfig config) {
    // 弹出确认对话框
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('确认删除'),
            content: Text('确定要删除配置 "${config.name}" 吗？'),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final appDocDir = await getApplicationSupportDirectory();
                  final configFile = File(
                    '${appDocDir.path}/$_configDir/${config.name}.json',
                  );

                  // 删除配置文件
                  if (configFile.existsSync()) {
                    configFile.deleteSync();
                  }

                  // 从配置列表中移除
                  setState(() {
                    final index = _configs.indexWhere(
                      (c) => c.name == config.name,
                    );
                    _configs.removeAt(index);

                    // 如果删除的是当前配置
                    if (_currentConfig?.name == config.name) {
                      _currentConfig = null; // 重置当前配置
                      _dirPath = '/';
                      if (_configs.isNotEmpty) {
                        _saveCurrentConfig(''); // 清空主配置记录
                      }
                      _initializeWebDAV(); // 会触发后续加载逻辑
                    }
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop(); // 关闭确认对话框
                  }
                },
                child: Text(
                  '删除',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  // 构建工具栏
  List<Widget> _sliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    return <Widget>[
      SliverOverlapAbsorber(
        handle: _overlapHandle,
        sliver: Container(
          key: _sliverAppBarKey, // 绑定 key
          child: SliverAppBar(
            floating: true,
            pinned: false,
            snap: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'CloudBrowser',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadFiles,
                tooltip: '刷新',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: SizedBox(
                height: 50,
                child: Align(
                  alignment: Alignment.centerLeft, // 左对齐
                  child: ListView(
                    controller: _breadcrumbScrollController,
                    primary: false, // 关键：禁用主滚动属性
                    physics: const ClampingScrollPhysics(), // 防止滚动传递
                    scrollDirection: Axis.horizontal,
                    children: _buildBreadcrumbs(), // 动态生成面包屑导航
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  // 主体内容构建方法
  Widget _buildBodyContent() {
    if (_errorMessage != null) {
      return _buildErrorPage();
    }

    // 新增配置空状态提示
    if (_configs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 48),
            SizedBox(height: 16),
            Text('暂无配置，请先创建WebDAV配置'),
            TextButton(
              onPressed: () => _showConfigDialog(),
              child: Text('创建新配置'),
            ),
          ],
        ),
      );
    }

    if (_currentConfig == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_queue, size: 48),
            SizedBox(height: 16),
            Text('请从侧边栏选择WebDAV配置'),
            TextButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: Text('打开配置列表'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_files.isEmpty) {
      return const Center(child: Text('此目录为空'));
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: kToolbarHeight + 31)),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final file = _files[index];
            return _buildFileItem(file, index);
          }, childCount: _files.length),
        ),
      ],
    );
  }

    // 列表项构建方法
  Widget _buildFileItem(webdav.File file, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: ListTile(
        hoverColor: Theme.of(context).colorScheme.primaryContainer,
        leading: Icon(
          file.isDir ?? false
              ? Icons.folder_outlined
              : lookupMimeType(file.name ?? '')?.startsWith('image/') ?? false
              ? Icons.image_outlined
              : lookupMimeType(file.name?? '')?.startsWith('video/')?? false
              ? Icons.video_library_outlined
              : lookupMimeType(file.name?? '')?.startsWith('audio/')?? false
              ? Icons.audio_file_outlined
              : lookupMimeType(file.name?? '')?.startsWith('text/')?? false
              ? Icons.text_snippet_outlined
              : Icons.insert_drive_file_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          file.name ?? '未命名文件',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          file.mTime?.toString() ?? '未知时间',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'Download',
              child: Text('下载'),
            ),
            PopupMenuItem(
              value: 'Rename',
              child: Text('重命名'),
            ),
            PopupMenuItem(
              value: 'Copy',
              child: Text('复制'),
            ),
            PopupMenuItem(
              value: 'Move',
              child: Text('移动'),
            ),
            PopupMenuItem(
              value: 'Delete',
              child: Text('删除'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'Download':
                // _downloadFile(file);
                break;
              case 'Rename':
                // _renameFile(file);
                break;
              case 'Copy':
                // _copyFiletoDir(file);
                break;
              case 'Move':
                // _moveFiletoDir(file);
                break;
              case 'Delete':
                // _deleteFile(file);
                break;
            }
          },
        ),
        onTap:
            file.isDir ?? false
                ? () {
                  final newPath = _buildPath(file.name!);
                  setState(() {
                    _dirPath = newPath;
                    _isFromBreadcrumb = false;
                    _updateBreadcrumbParts();
                  });
                  _triggerBreadcrumbScroll();
                  _loadFiles();
                }
                : () {}
      ),
    );
  }

  // 面包屑重建方法
  void _rebuildBreadcrumb() {
    // 修复路径解析逻辑
    final cleanPath = _dirPath
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/|/$'), '');
    _breadcrumbParts = cleanPath.split('/');

    // 处理根目录情况
    if (_dirPath == '/' || cleanPath.isEmpty) {
      _breadcrumbParts = [];
    }
  }

  // 更新_breadcrumbParts的方法，仅在非面包屑导航时调用
  void _updateBreadcrumbParts() {
    if (!_isFromBreadcrumb) {
      String path = _dirPath;
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      setState(() {
        _breadcrumbParts = path.isEmpty ? [] : path.split('/');
      });
    }
  }

  List<Widget> _buildBreadcrumbs() {
    List<Widget> buttons = [];
    String accumulatedPath = '/';

    buttons.add(SizedBox(width: 48));
    buttons.add(_buildCrumbButton(label: '/', targetPath: accumulatedPath));

    for (String part in _breadcrumbParts) {
      // 添加分隔符
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.navigate_next),
        ),
      );
      accumulatedPath += '$part/'; // 更新路径
      buttons.add(_buildCrumbButton(label: part, targetPath: accumulatedPath));
    }

    return buttons;
  }

  Widget _buildCrumbButton({
    required String label,
    required String targetPath,
  }) {
    final bool isCurrent = targetPath == _dirPath;
    return TextButton(
      key: isCurrent ? _currentBreadcrumbKey : null, // 标记当前目录的key
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        if (!isCurrent) {
          setState(() {
            _dirPath = targetPath;
            _isFromBreadcrumb = true;
            _updateBreadcrumbParts(); // 需要确保更新面包屑
          });
          _triggerBreadcrumbScroll(); // 新增滚动触发
          _loadFiles();
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color:
              isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _triggerBreadcrumbScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentBreadcrumbKey.currentContext?.mounted ?? false) {
        final scrollable = Scrollable.maybeOf(
          _currentBreadcrumbKey.currentContext!,
        );
        scrollable?.position.ensureVisible(
          _currentBreadcrumbKey.currentContext!.findRenderObject()!,
          duration: const Duration(milliseconds: 150),
          alignment: 0.1, // 微调确保完全可见
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildErrorPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '未知错误',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
