import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mysql_utils/mysql_utils.dart';

void main() async {
  // 确保Flutter初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 运行应用并处理数据库连接
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MySQL Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MySQL连接示例'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _connectionStatus = '未连接';
  List<Map<String, dynamic>> _queryResults = [];
  bool _isLoading = false;

  late MysqlUtils db;

  // 创建带 CA 证书的 SecurityContext
  SecurityContext _createSecurityContext() {
    final context = SecurityContext();
    final caCertPath = 'isrgrootx1.pem'; // 替换为你的 CA 证书路径

    // 如果证书在 assets 中，需要先读取它
    // 示例：使用 rootBundle.loadString 加载 assets 文件
    // 注意：你可能需要将证书写入临时目录后再加载
    context.setTrustedCertificates(caCertPath);
    return context;
  }

  // 连接数据库
  Future<void> _connectToDatabase() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = '连接中...';
    });

    try {
      db = MysqlUtils(
        settings: MysqlUtilsSettings(
          host: 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com',
          port: 4000,
          user: '2BqWAh2jJoWpbeu.root',
          password: 'YPAXDhzysitNn3t6',
          db: 'MyMonenyTrail',
          secure: true,
          prefix: '',
          maxConnections: 10000,
          timeoutMs: 10000,
          sqlEscape: true,
          pool: true,
          collation: 'utf8mb4_general_ci',
          securityContext: _createSecurityContext(),
        ),
        errorLog: (error) {
          print(error);
        },
        sqlLog: (sql) {
          print(sql);
        },
        connectInit: (db1) async {
          print('连接成功回调');
        },
      );


      await Future.delayed(Duration(seconds: 1)); // 模拟延迟确保连接完成
      setState(() {
        _connectionStatus = '连接成功';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '连接失败: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 查询数据
  Future<void> _queryData() async {
    if (_connectionStatus != '连接成功') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先连接数据库')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _queryResults = [];
    });

    try {
      final result = await db.getAll(table: 'user', fields: '*', debug: true);
      print(result);
      if (result is List<dynamic>) {
        // 过滤并转换每个元素为 Map<String, dynamic>
        final List<Map<String, dynamic>> dataList = result
            .where((item) => item is Map<dynamic, dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        setState(() {
          _queryResults = dataList;
        });
      } else {
        throw '数据格式错误，不是 List<dynamic>';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查询失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _insertData() async {
    if (_connectionStatus != '连接成功') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先连接数据库')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await db.insert(
        table: 'user',
        insertData: {
          'username': 'cosy',
          'password': 'asd38f88gy8t8'
        },
      );

      if (result != null && result != '') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('插入数据成功')),
        );

      } else {
        throw '插入失败';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('插入失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  

  // 关闭数据库连接
  Future<void> _closeConnection() async {
    if (_connectionStatus == '连接成功') {
      try {
        await db.close();
        setState(() {
          _connectionStatus = '已断开连接';
        });
      } catch (e) {
        setState(() {
          _connectionStatus = '断开连接失败: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('连接状态: $_connectionStatus'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _connectToDatabase,
              child: const Text('连接数据库'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _insertData,
              child: const Text('插入数据'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _queryData,
              child: const Text('查询数据'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _closeConnection,
              child: const Text('关闭连接'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_queryResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _queryResults.length,
                  itemBuilder: (context, index) {
                    final row = _queryResults[index];
                    return ListTile(
                      title: Text('用户名: ${row['username']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${row['id']}'),
                          Text('创建时间: ${row['create_time']}'),
                          Text('最后登录时间: ${row['lastsign_time']}'),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              const Text('暂无数据')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}