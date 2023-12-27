import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

Future<ItemData> fetchItemData(String barCode) async {
  final response = await http
      .get(Uri.parse('https://autobahn.eu.pythonanywhere.com/$barCode'));

  return ItemData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

// Класс описывает структуру цены товара в отдельном магазине
class Shop {
  final String name;
  final double price;

  Shop(this.name, this.price);

  Shop.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        price = json["price"] as double;
}

// Класс описывает структуру результата поиска, то есть данные по товару
class ItemData {
  final int id;
  final String name;
  final List<Shop> shops;

  ItemData(this.id, this.name, this.shops);

  ItemData.fromJson(Map<String, dynamic> json)
      : id = json["id"] as int,
        name = json["name"] as String,
        shops = (json["shops"] as List).map((s) => Shop.fromJson(s)).toList();
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

// В отдельную функцию вынесена отрисовка результата поиска
Widget renderResult(item) => Column(children: <Widget>[
      Text(item.data!.id.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(item.data!.name),
      Column(
        children: [
          for (var shop in item.data!.shops)
            Card(
              child: ListTile(
                title: Text(shop.name),
                subtitle: Text(shop.price.toString()),
              ),
            ),
        ],
      )
    ]);

class _MyAppState extends State<MyApp> {
  late Future<ItemData> futureItemData;
  String _scanBarcode = '4607084351385';

  void fetchBarCodeData() {
    futureItemData = fetchItemData(_scanBarcode);
  }

  @override
  void initState() {
    super.initState();
    fetchBarCodeData();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Сканировать', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
      fetchBarCodeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Scaffold(
            appBar: AppBar(title: const Text('Результаты поиска')),
            body: Center(
                child: FutureBuilder<ItemData>(
              future: futureItemData,
              builder: (context, item) {
                if (item.hasData) {
                  // Вызываем функцию отрисовки результата
                  return renderResult(item);
                } else if (item.hasError) {
                  return Text('${item.error}');
                }

                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            )),
            floatingActionButton: FloatingActionButton(
                onPressed: () => scanBarcodeNormal(),
                child: const Text('Скан'))));
  }
}
