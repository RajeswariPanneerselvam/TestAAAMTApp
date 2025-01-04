import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:test_aaamt_app/model/user_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Users List'),
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
  File? galleryFile;
  final picker = ImagePicker();
  int? image_index;
  List<User> users = [];
  String? _currentAddress;
  Position? _currentPosition;
  static const snackBar = SnackBar(content: Text("No user data found,Please check your internet connection"));
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    // List<Placemark> placemarks= await placemarkFromCoordinates( _currentPosition!.latitude, _currentPosition!.longitude);
    // Placemark place = placemarks[0];
    // print(place);
    print( _currentPosition!.latitude);
    print(_currentPosition!.longitude);
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      print(placemarks);
      Placemark place = placemarks[0];
      setState(() {

        _currentAddress =
        '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      print(e);
      debugPrint(e);
    });
  }


  Future<List<User>>  getUserData() async{
   String url="https://reqres.in/api/users?page=2";
   final response=await http.get(Uri.parse(url));
   if (response.statusCode == 200) {
     var responseData = json.decode(response.body);
     print(responseData['data']);
     // apiModel=responseData;
     // var data=apiModel.data;

     for (var item in responseData['data']) {
       User user = User(
           id: item["id"],
           email: item["email"],
           first_name: item["first_name"],
           last_name: item["last_name"],
           avatar:item["avatar"],
           // gallery_file: galleryFile!
       );
       print(user);
       //Adding user to the list.
       setState(() {
         users.add(user);
       });

    }
     return users;
     // apiModel=responseData;
     // print("ApiModel");
     // print(apiModel);
     // return apiModel;
   }else{
     ScaffoldMessenger.of(context).showSnackBar(snackBar);
     throw Exception('Failed to load data');
     
   }
  }
  void _showPicker({
    required BuildContext context,required index
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  getImage(ImageSource.gallery,index);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera,index);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future getImage(
      ImageSource img,int index
      ) async {
    final pickedFile = await picker.pickImage(source: img);
    XFile? xfilePick = pickedFile;
    setState(
          () {
        if (xfilePick != null) {
          setState(() {
            image_index=index;
          });
          galleryFile = File(pickedFile!.path);
          // users[index].gallery_file=galleryFile!;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(// is this context <<<
              const SnackBar(content: Text('Nothing is selected')));
        }
      },
    );
  }

 @override
  void initState() {
    // TODO: implement initState
   _getCurrentPosition();
    getUserData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title,style:TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body:users.length==0?CircularProgressIndicator(): Container(
        child:
        Column(
         children: [
            SizedBox(height: 10,),
            Text("User Current Location",style:TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.bold)),
            SizedBox(height: 10,),
            Text("Latitude : ${_currentPosition?.latitude ?? ""}",style:TextStyle(fontSize: 16,color: Colors.black)),
            SizedBox(height: 5,),
            Text("Longitude : ${_currentPosition?.longitude ?? ""}",style:TextStyle(fontSize: 16,color: Colors.black)),
            SizedBox(height: 5,),
            Text("Address :  ${_currentAddress ?? ""}",style:TextStyle(fontSize: 16,color: Colors.black)),
            SizedBox(height: 20,),

            Expanded(
              child:
              ListView.builder(
                itemCount:users.length,
                itemBuilder:(context,index){
                  return Container(
                  child:
                      Column(
                        children:
                        [

                          Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            galleryFile==null?
                            Container(
                              width:100,
                                height: 100,
                               child: Image.network(users[index].avatar,width: 100,height: 100)):
                            index==image_index ?Image.file(galleryFile!,width: 100,height: 100): Image.network(users[index].avatar,width: 100,height: 100),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(users[index].first_name+" "+users[index].last_name,style:TextStyle(fontSize: 14,color: Colors.black,fontWeight: FontWeight.bold)),
                                SizedBox(height: 10,),
                                Text(users[index].email,style:TextStyle(fontSize: 14,color: Colors.black,fontWeight: FontWeight.bold))
                              ],
                            ),
                            IconButton(onPressed: () {
                           _showPicker(context: context,index:index);
                            },
                                icon: Icon(Icons.upload_file,size: 20,color: Theme.of(context).colorScheme.primary)),

              
                          ],
                        ),
                          SizedBox(height: 10,)
                  ]
                      )
              
                  );
                }
              ),
            )

          ]


       ),
      ),
     // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
