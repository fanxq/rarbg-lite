import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './rarbgapi.dart';

void main() {
  // 强制竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'RarbgLite'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _data = [];
  RarbgApi _rarbgApi = RarbgApi();
  String _selectedText = 'MOVIES_XVID';
  int _selectedValue = 14;
  bool _isSearching = false;
  bool _isError = false;
  String _errorMessage;

  void _copyLink(String link) {
    ClipboardData tData = ClipboardData(text: link);
    Clipboard.setData(tData);
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('已复制'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _search(String value) async {
    if (value == null || value.trim().isEmpty) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('请输入搜索内容'),
        duration: Duration(seconds: 2),
      ));
    }
    try {
      setState(() {
        _data.clear();
        _isSearching = true;
        _isError = false;
      });
      var result = await _rarbgApi.search(value, _selectedValue);
      setState(() {
        if (result != null) {
          var resultData = result?.data;
          if (resultData != null && resultData['torrent_results'] != null) {
            _data = resultData['torrent_results'];
          } else {
            throw '没有找到相关内容';
          }
        }
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  Widget buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
              child: TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.all(10),
                border: OutlineInputBorder(),
                hintText: 'search'),
            onSubmitted: _search,
          ))
        ],
      ),
    );
  }

  void showSettingDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          int selectedCategoryValue = _selectedValue;
          String selectedCategoryText = _selectedText;
          return AlertDialog(
            title: Text('选择类别',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                  child: Wrap(
                children: RarbgApi.categories.keys.toList().map((categoryText) {
                  int categoryValue = RarbgApi.categories[categoryText];
                  print(categoryValue);
                  bool isSelected = categoryText == selectedCategoryText;
                  return ChoiceChip(
                    label: Text(categoryText,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    onSelected: (bool value) {
                      setState(() {
                        selectedCategoryText =
                            value ? categoryText : 'MOVIES_XVID';
                        selectedCategoryValue = value ? categoryValue : 14;
                      });
                    },
                  );
                }).toList(),
              ));
            }),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    setState(() {
                      _selectedValue = selectedCategoryValue;
                      _selectedText = selectedCategoryText;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('确定'))
            ],
          );
        });
  }

  Widget buildCategroySection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('类型',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ))),
        Chip(
          label: Text('$_selectedText', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        Expanded(child: Container(width: 0.0, height: 0.0)),
        IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showSettingDialog(context);
            })
      ]),
    );
  }

  Widget buildLoadingIndicator() {
    return Offstage(
      offstage: _isSearching ? false : true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 40.0),
            width: 40.0,
            height: 40.0,
            child: CircularProgressIndicator(),
          ),
          Container(
            margin: const EdgeInsets.only(top: 15.0),
            child: Text('搜索中...', style: TextStyle(fontSize: 16.0)),
          )
        ],
      ),
    );
  }

  Widget buildErrorMessageDisplaySection() {
    return Offstage(
      offstage: !_isSearching && _isError ? false : true,
      child: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Center(child: Text('$_errorMessage', style: TextStyle(fontSize: 20.0, color: Colors.black45),)),
      )
    );
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          buildSearchBar(context),
          buildCategroySection(context),
          buildLoadingIndicator(),
          buildErrorMessageDisplaySection(),
          Expanded(
              child: Offstage(
                  offstage: !_isSearching && !_isError ? false : true,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(children: <Widget>[
                        Text(
                          '${_data[index]['filename']}',
                          softWrap: true,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18.0,
                              color: Colors.black87),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                                child: Text(
                              '${_data[index]['download']}',
                              softWrap: true,
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.black54),
                            )),
                            Column(children: <Widget>[
                              IconButton(
                                  icon: Icon(
                                    Icons.content_copy,
                                    size: 30.0,
                                    color: Colors.blue.shade600,
                                  ),
                                  onPressed: () =>
                                      _copyLink(_data[index]['download'])),
                              Text(
                                '复制',
                                style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: 12.0),
                              )
                            ])
                          ],
                        )
                      ]);
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  )))
        ],
      ),
    );
  }
}
