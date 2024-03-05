import 'dart:convert';
import 'dart:html' hide File, Platform;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../common/common.dart';
import '../models/item_model.dart';

import 'package:http/http.dart' as http;

TextEditingController itemNameController = TextEditingController();
TextEditingController itemPriceController = TextEditingController();
TextEditingController shopNameController = TextEditingController();
String imageLink = '';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  int currentPageIndex = 0;
  late final TabController _tabController;

  List<OrderData> ordersList = [];
  List<OrderData> ordersDeliveredList = [];

  void deleteItem(String key) {
    // Initialize Firebase
    FirebaseDatabase database = FirebaseDatabase.instance;

    // Reference to your database
    DatabaseReference reference = database.ref();

    // Reference to the specific node with the given key
    DatabaseReference itemReference = reference.child('shops').child(key);

    // Delete the item
    itemReference.remove().then((_) {
      if (kDebugMode) {
        print("Item deleted successfully");
      }
    }).catchError((error) {
      if (kDebugMode) {
        print("Failed to delete item: $error");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference fb = FirebaseDatabase.instance.ref().child("Orders");
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(appName),
        bottom: currentPageIndex == 0
            ? TabBar(controller: _tabController, tabs: const <Widget>[
                Tab(
                  text: 'Not Delivered',
                  icon: Icon(Icons.clear),
                ),
                Tab(
                  text: 'Delivered',
                  icon: Icon(Icons.check),
                ),
              ])
            : null,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add_box_rounded),
            icon: Icon(Icons.add_box_outlined),
            label: 'Menu',
          ),
        ],
      ),
      body: [
        //Orders
        fb.onValue.length == 0
            ? const Center(child: Text('No orders'))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder(
                    stream: kIsWeb ? FirebaseDatabase.instance.ref().child("Orders").onValue : fb.onValue,
                    builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      List<OrderData> items = [];
                      List<OrderData> deliveredItems = [];

                      if (snapshot.hasData) {
                        Map<dynamic, dynamic> map =
                            (snapshot.data?.snapshot.value as Map<dynamic, dynamic>).cast<String, dynamic>();

                        items.clear();
                        deliveredItems.clear();
                        map.forEach((key, value) {
                          final email = value["email"] ?? '';
                          final name = value["name"] ?? '';
                          final orderTime = value["order_time"];
                          final orderDetails = value["order_details"];
                          final delivered = value["delivered"];
                          final key = value["key"];
                          final UID = value["uid"] ?? '';
                          // print('culprit = ${orderTime.toString()}, $email , ${fb.onValue.length}');
                          final DateTime dateTime = DateTime.parse(orderTime);

                          if (delivered == true) {
                            orderDetails == ''
                                ? null
                                : deliveredItems.add(OrderData(email, name, dateTime, orderDetails, UID, delivered, key));
                          } else if (delivered == false) {
                            orderDetails == ''
                                ? null
                                : items.add(OrderData(email, name, dateTime, orderDetails, UID, delivered, key));
                          }
                        });
                        items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                        deliveredItems.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            items.isEmpty
                                ? const Center(child: Text('No orders'))
                                : ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final dateTime = DateFormat('dd-MM-yyyy hh:mm a').format(items[index].dateTime);
                                      return Card(
                                        child: ListTile(
                                          leading: Text('${index + 1}'),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                                              return OrderDetail(
                                                jsonData: items[index].orderDetails,
                                                name: items[index].name,
                                                uid: items[index].UID,
                                                delivered: items[index].delivered,
                                                key1: items[index].key,
                                              );
                                            }));
                                          },
                                          title: Text(items[index].name),
                                          subtitle: Text(dateTime),
                                        ),
                                      );
                                    },
                                  ),
                            deliveredItems.isEmpty
                                ? const Center(child: Text('No orders'))
                                : ListView.builder(
                                    itemCount: deliveredItems.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final dateTime = DateFormat('dd-MM-yyyy hh:mm a').format(deliveredItems[index].dateTime);
                                      return Card(
                                        child: ListTile(
                                          leading: Text('${index + 1}'),
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                                              return OrderDetail(
                                                jsonData: deliveredItems[index].orderDetails,
                                                name: deliveredItems[index].name,
                                                uid: deliveredItems[index].UID,
                                                delivered: deliveredItems[index].delivered,
                                                key1: deliveredItems[index].key,
                                              );
                                            }));
                                          },
                                          title: Text(deliveredItems[index].name),
                                          subtitle: Text(dateTime.toString()),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        );
                      } else {
                        return const Center(child: Text('No orders'));
                      }
                    }),
              ),
        //Menu
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref().child("shops").onValue,
              builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
                List<ItemModel> items = [];

                if (snapshot.hasData) {
                  Map<dynamic, dynamic> map = (snapshot.data?.snapshot.value as Map<dynamic, dynamic>).cast<String, dynamic>();

                  items.clear();

                  map.forEach((dynamic, v) => items.add(ItemModel(
                      v["shop_name"], v["shop_availability"], v["item_name"], v["key"], v["item_price"], v["shop_image"])));

                  return items.isEmpty
                      ? const CircularProgressIndicator()
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, int index) => Card(
                                child: ListTile(
                                  title: Text(items[index].itemName),
                                  subtitle: Text('Rs: ${items[index].itemPrice.toString()}'),
                                  leading: Image.network(loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  }, width: 50, fit: BoxFit.cover, items[index].itemImage),
                                  trailing: GestureDetector(
                                    onTap: () {
                                      ///add confirm delete
                                      deleteItem(items[index].key);
                                    },
                                    child: const Icon(CupertinoIcons.minus_circle),
                                  ),
                                ),
                              ));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
        ),
      ][currentPageIndex],
      floatingActionButton: Visibility(
        visible: currentPageIndex == 0 ? false : true,
        child: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            showModalBottomSheet(
                // isScrollControlled: true,
                scrollControlDisabledMaxHeightRatio: 0.9,
                context: context,
                builder: (context) =>
                    StatefulBuilder(builder: (BuildContext context, StateSetter setState) => const AddMenuBottomSheet()));
          },
        ),
      ),
    );
  }
}

class OrderData {
  final String email;
  final String name;
  final String orderDetails;
  final String key;
  final DateTime dateTime;
  final String UID;
  final bool delivered;

  OrderData(
    this.email,
    this.name,
    this.dateTime,
    this.orderDetails,
    this.UID,
    this.delivered,
    this.key,
  );
}

class OrderDetail extends StatelessWidget {
  const OrderDetail(
      {super.key, required this.jsonData, required this.name, required this.uid, required this.delivered, required this.key1});

  final String jsonData;
  final String name, key1;
  final String uid;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(jsonDecode(jsonData));

    void deleteOrderFields() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("Orders/$key1");

        Map<String, dynamic> updateData = {
          "delivered": true,
        };

        userRef.update(updateData);
      }
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer $name'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                          trailing: Text('Rs: ${data[index]['price'] * data[index]['count']}'),
                          title: Text('${data[index]['count']} x ${data[index]['foodName']}')),
                    );
                  }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: delivered
                    ? null
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(fixedSize: Size(size.width, 70)),
                        child: const Text('Delivered'),
                        onPressed: () {
                          deleteOrderFields();
                          Navigator.pop(context);
                        }),
              ),
              const Text('*only click this after collecting money and delivered food')
            ],
          ),
        ),
      ),
    );
  }
}

Widget textFormFieldBuilder(String labelText, TextInputType textInputType, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextFormField(
      controller: controller,
      keyboardType: textInputType,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class AddMenuBottomSheet extends StatefulWidget {
  const AddMenuBottomSheet({super.key});

  @override
  State<AddMenuBottomSheet> createState() => _AddMenuBottomSheetState();
}

class _AddMenuBottomSheetState extends State<AddMenuBottomSheet> {
  bool shopAvailabilityBool = false;
  List<File> myFile = [];
  final ImagePicker picker = ImagePicker();
  //String githubRawText = '';
  Future<String> fetchGitHubRawText() async {
    final response =
        await http.get(Uri.parse('https://raw.githubusercontent.com/santhosh-D-subramani/freshness_aimodel/main/ai.txt'));
    print('to string: ${response.body.toString()}');
    print(response.body);
    return response.statusCode == 200 ? response.body.toString() : '';
  }

  Future<Map<String, dynamic>> sendImage(Uint8List imageBytes) async {
    //const url = 'http://localhost:5000/predict_mask';
    //const url = 'https://sasuke3215-ai-model.hf.space/predict_freshness';
    // const url = 'http://luciferotis.pythonanywhere.com/predict_mask';
    //var url = githubRawText == '' ? 'http://localhost:5000/predict_freshness' : githubRawText;
    String url = 'http://localhost:5000/predict_freshness';
    print(url);
    // Convert Uint8List to base64-encoded string
    String base64Image = base64Encode(imageBytes);
    // print(base64Image);
    await Clipboard.setData(ClipboardData(text: base64Image));
    print('Base64 Image Length: ${base64Image.length}');

    final Map<String, dynamic> requestBody = {
      'image': base64Image,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print(response.request?.url.toString());
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else {
        print('Error: ${response.reasonPhrase}');
        return {'error': 'Failed to make a prediction'};
      }
    } catch (error) {
      print('Error: $error');
      return {'error': 'Failed to connect to the server'};
    }
  }

  Future<void> uploadImageToFirebase(BuildContext context, File? imageFile, Uint8List? imageUint8List) async {
    try {
      // Create a unique filename for the image using current timestamp
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Reference to the Firebase Storage bucket
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('images/$fileName.jpg');

      // Create a custom progress dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.0),
                  Text('Uploading...'),
                ],
              ),
            ),
          );
        },
      );
      if (kDebugMode) {
        print('object');
      }
      // Upload the file to Firebase Storage
      kIsWeb
          ? imageUint8List != null
              ? await ref.putData(imageUint8List)
              : kDebugMode
                  ? print('>---Uint8List null')
                  : null
          : imageFile != null
              ? await ref.putFile(imageFile)
              : kDebugMode
                  ? print('>---image file null')
                  : null;

      // Get the download URL for the uploaded image
      String downloadURL = await ref.getDownloadURL();

      imageLink = downloadURL;

      // Close the custom progress dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Print the download URL (you can save it in your database or use it as needed)
      if (kDebugMode) {
        print("Image uploaded. Download URL: $downloadURL");
      }
    } catch (e) {
      // Close the custom progress dialog in case of an error
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (kDebugMode) {
        print("Error uploading image: $e");
      }
    }
  }

  void addToFirebase(
    String itemName,
    shopAvailability,
    shopImage,
    shopName,
    int itemPrice,
    int freshness,
    double freshnessProbability,
  ) async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    // Generate a new key using push()
    String? newKey = databaseReference.child('shops').push().key;

    Map<String, dynamic> shopData = {
      "item_name": itemName,
      "item_price": itemPrice,
      "key": newKey!,
      "shop_availability": shopAvailability,
      "shop_image": shopImage,
      "shop_name": shopName,
      "freshness": freshness,
      "freshnessProbability": freshnessProbability,
    };

    // Assuming you want to create a new child node under 'shops' with a unique key
    databaseReference.child('shops').child(newKey).set(shopData);
  }

  String formatDouble(double value) {
    String stringValue = value.toString();

    // Find the index of the first non-zero digit
    int nonZeroIndex = stringValue.indexOf(RegExp('[1-9]'));

    // If non-zero digit is found, format the remaining digits
    if (nonZeroIndex != -1) {
      String formattedValue = stringValue.substring(nonZeroIndex);
      // Truncate to two decimal places
      if (formattedValue.length > 2) {
        formattedValue = formattedValue.substring(0, 2);
      }
      return formattedValue;
    }

    // If all digits are zero, return "0"
    return "0";
  }

  List predictions = [];
  bool loading = false;
  Uint8List? prdImage;
  var predictionResult;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const SizedBox(
          height: 16,
        ),
        const Text(
          '    Add Menu',
          style: TextStyle(fontSize: 20),
        ),
        textFormFieldBuilder('Item Name', TextInputType.text, itemNameController),
        textFormFieldBuilder('Item Price', TextInputType.number, itemPriceController),
        textFormFieldBuilder('Shop Name', TextInputType.text, shopNameController),
        CheckboxListTile(
          tileColor: shopAvailabilityBool == true ? Colors.green : Colors.red,
          value: shopAvailabilityBool,
          onChanged: (bool? onChanged) {
            if (kDebugMode) {
              print(onChanged);
            }
            setState(() {
              shopAvailabilityBool = onChanged!;
            });
          },
          title: const Text('Shop Availability'),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: () async {
                  predictions.clear();
                  if (kIsWeb) {
                    Uint8List? prdImage1 = await ImagePickerWeb.getImageAsBytes();

                    setState(() {
                      prdImage = prdImage1;
                    });
                    if (prdImage1 != null) {
                      predictionResult = await sendImage(prdImage1);

                      setState(() {
                        predictionResult;
                        predictions.add(predictionResult);
                        print(predictions[0]['Freshness'].toString());
                        print(predictions[0]['Freshness_probability'].toString());
                        loading = true;
                      });
                      print('Prediction Result: $predictionResult');
                    } else {
                      print('prdImage empty');
                    }
                    if (context.mounted) {
                      uploadImageToFirebase(context, null, prdImage);
                    }
                  } else if (Platform.isAndroid) {
                    var file = await picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      myFile.add(File(file!.path));
                    });
                    if (context.mounted) {
                      uploadImageToFirebase(context, myFile.last, null);
                    }
                  }
                  setState(() {});
                },
                child: const Text('Upload Image')),
          ],
        ),
        Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 150,
          child: kIsWeb
              ? prdImage != null
                  ? Column(
                      children: [
                        Expanded(
                          child: Image.memory(
                            prdImage!,
                          ),
                        ),
                        //Text('Freshness : ${predictions[0]['Freshness']}'),
                        Text('${formatDouble(predictions[0]['Freshness_probability'])}% Fresh')
                      ],
                    )
                  : const Text('No image selected')
              : myFile.isEmpty
                  ? const Text('No image selected')
                  : Image.file(myFile[0], fit: BoxFit.cover),
        ),
        ElevatedButton(
            onPressed: () {
              addToFirebase(itemNameController.text, shopAvailabilityBool.toString(), imageLink, shopNameController.text,
                  int.parse(itemPriceController.text), predictions[0]['Freshness'], predictions[0]['Freshness_probability']);
              itemNameController.clear();
              itemPriceController.clear();
              shopAvailabilityBool = false;
              imageLink = "";
              predictions.clear();
              shopNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Upload Menu To Server'))
      ],
    );
  }
}
