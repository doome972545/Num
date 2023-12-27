import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as IO;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'palette.dart';

// NAiFlutter
// Copyright R&D Computer System Co., Ltd.

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAiFlutter',
      //theme: ThemeData(primarySwatch: Colors.blue),
      theme: ThemeData(primarySwatch: Palette.kToDark),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = const MethodChannel('flutter.native/helper');
  TextEditingController _textController = TextEditingController();
  static const int NA_POPUP = 0x80;
  // ignore: unused_field
  static const int NA_FIRST = 0x40;
  static const int NA_SCAN = 0x10;
  static const int NA_BLE1 = 0x08;
  static const int NA_BLE0 = 0x04;
  static const int NA_BT = 0x02;
  static const int NA_USB = 0x01;

  static const int NA_SUCCESS = 0;
  static const int NA_INTERNAL_ERROR = -1;
  static const int NA_INVALID_LICENSE = -2;
  static const int NA_READER_NOT_FOUND = -3;
  static const int NA_CONNECTION_ERROR = -4;
  static const int NA_GET_PHOTO_ERROR = -5;
  static const int NA_GET_TEXT_ERROR = -6;
  static const int NA_INVALID_CARD = -7;
  static const int NA_UNKNOWN_CARD_VERSION = -8;
  static const int NA_DISCONNECTION_ERROR = -9;
  static const int NA_INIT_ERROR = -10;
  static const int NA_READER_NOT_SUPPORTED = -11;
  static const int NA_LICENSE_FILE_ERROR = -12;
  static const int NA_PARAMETERS_ERROR = -13;
  static const int NA_INTERNET_ERROR = -15;
  static const int NA_CARD_NOT_FOUND = -16;
  static const int NA_BLUETOOTH_DISABLED = -17;
  static const int NA_LICENSE_UPDATE_ERROR = -18;
  static const int NA_STORAGE_PERMISSION_ERROR = -31;
  static const int NA_LOCATION_PERMISSION_ERROR = -32;
  static const int NA_BLUETOOTH_PERMISSION_ERROR = -33;
  static const int NA_LOCATION_SERVICE_ERROR = -41;

  late Uint8List bytesPhoto = Uint8List.fromList([]);
  late Uint8List bytesAppPhoto = Uint8List.fromList([]);
  String idCardNumber = '';
  Map<Permission, PermissionStatus> statuses = new Map();

  String sAppName = "";
  String readerName = 'Reader: ';
  String textResult = "";
  String sLicenseInfo = "";
  String sSoftwareInfo = "";
  String folder = "";
  String sLICFileName = "";
  String rootFolder = "";
  String sLicFile = "";
  String parameterOpenLib = "";
  bool isEnabled = true;
  bool isVisible = false;
  bool isReaderConnected = false;

  @override
  void initState() {
    super.initState();
    if (IO.Platform.isAndroid) {
      // Android-specific code/UI Component
      sAppName = "NAiFlutter 0.2.1302 (Android)";
    } else if (IO.Platform.isIOS) {
      // iOS-specific code/UI Component
      sAppName = "NAiFlutter 0.2.1302 (iOS)";
    }

    platform.setMethodCallHandler(_fromNative);

    setState(() {
      sAppName = sAppName;
    });

    if (IO.Platform.isAndroid) {
      initAndroid();
    } else if (IO.Platform.isIOS) {
      initIOS();
    }
  }

  //////////////////////////////// Initialize for Android ////////////////////////////////
  void initAndroid() async {
    // Android-specific code/UI Component
    folder = "/" + "NAiFlutter";
    sLICFileName = "/" + "rdnidlib.dls";
    await getFilesDirDF();
    await setAppLogo();

    if (await setListenerDF() == false) return;
    if (await getSoftwareInfoDF() == false) return;
    if (await writeLicFileDF() == false) return;
    if (await setPermissionsDF() == false) return;
    if (await openLibDF() == false) return;
    if (await getLicenseInfoDF() == false) return;

    requestPermission();

    setState(() {
      isEnabled = true;
    });
  }

  //////////////////////////////// Initialize for IOS ////////////////////////////////
  void initIOS() async {
    // IOS-specific code/UI Component
    folder = "/" + "NAiFlutter";
    sLICFileName = "/" + "rdnidlib.dlt";
    await getFilesDirDF();
    await setAppLogo();

    if (await getSoftwareInfoDF() == false) return;
    if (await openLibDF() == false) return;
    if (await getLicenseInfoDF() == false) return;

    setState(() {
      isEnabled = true;
    });
  }

  //////////////////////////////// Button Find Reader ////////////////////////////////
  Future<void> buttonFindReader() async {
    isReaderConnected = false;
    String text = "Reader scanning...";
    setState(() {
      isEnabled = false;
      textResult = "";
      readerName = text;
      bytesPhoto = bytesAppPhoto;
    });

    // ===================== Get Reader List ======================== //
    var parts = await getReaderListDF();
    var returnCode = int.parse(parts[0].trim());

    if (parts == null || returnCode == 0 || returnCode == -3) {
      setState(() {
        readerName = 'Reader: ';
        isEnabled = true;
        textResult = "-3 Reader not found.";
      });
    } else if (returnCode < 0) {
      setState(() {
        isEnabled = true;
        readerName = 'Reader: ';
        textResult = checkException(returnCode);
      });
    } else if (returnCode > 0) {
      String textReaderName = parts[1].trim();
      setState(() {
        readerName = "Reader selecting...";
      });
      // ===================== Select Reader ======================== //
      if (await selectReaderDF(textReaderName) == true) {
        // ===================== Get Reader Info ======================== //
        await getReaderInfoDF();

        // ===================== Get License Info ======================== //
        await getLicenseInfoDF();
      }
    }
    setState(() {
      isEnabled = true;
    });
    buttonRead();
  }

  //////////////////////////////// Button Read Card ////////////////////////////////
  Future<void> buttonRead() async {
    String text = "Reading...";
    setState(() {
      isEnabled = false;
      bytesPhoto = bytesAppPhoto;
      textResult = text;
      textResult = idCardNumber;
    });

    try {
      // ===================== Check Card Status ======================== //
      if (IO.Platform.isIOS) {
        int returnCode = await getCardStatusDF();
        if (returnCode != 1) {
          text = checkException(returnCode);

          if (isReaderConnected != true) {
            text = "-3 Reader not found.";
          }
          setState(() {
            textResult = text;
            isEnabled = true;
          });
          return;
        }
      }
      // ===================== Connect Card ======================== //
      int startTime = new DateTime.now().millisecondsSinceEpoch;
      int resConnect = await connectCardDF();
      if (resConnect != NA_SUCCESS) {
        setState(() {
          textResult = checkException(resConnect);
          isEnabled = true;
        });
        return;
      }

      // ===================== Get Text ======================== //
      int returnCode = -1;
      var parts = await getTextDF();
      int endTime = new DateTime.now().millisecondsSinceEpoch;
      double readTextTime = ((endTime - startTime) / 1000);

      if (parts == null)
        returnCode = NA_GET_TEXT_ERROR;
      else {
        returnCode = int.parse(parts[0].trim());
        text = parts[1].trim();
        // String extractIdCardNumber(String text) {
        // ตรวจสอบว่า text มีข้อมูลหรือไม่
        //   if (text != null && text.length >= 13) {
        //     // ดึงเลขบัตรประชาชนตั้งแต่ตำแหน่งที่ 0 ถึง 12 (รวมถึงตำแหน่งที่ 12)
        //     String idCardNumber = text.substring(0, 13);
        //     return idCardNumber;
        //   } else {
        //     return "ไม่พบข้อมูลเลขบัตรประชาชน";
        //   }
        // }

        // String idCardNumber = extractIdCardNumber(text);

        // Display or use the ID card number as needed
        List<String> x = text.split("#");

        // เลือกข้อมูลที่ต้องการ
        String idCardNumbe = x[0];
        String titleTH = x[1];
        String firstNameTH = x[2];
        String lastNameTH = x[4];
        String titleEN = x[5];
        String firstNameEN = x[6];
        String lastNameEN = x[8];
        String houseNumber = x[9];
        String village = x[10];
        String subDistrict = x[14];
        String district = x[15];
        String province = x[16];
        String addressType = x[17];
        String birthDate = x[18];
        String address = x[19];
        String issueDate = x[20];
        String expireDate = x[21];
        String personalNumber = x[22];
        print("ID Card Number: $idCardNumbe");
        print("Name: $titleTH $firstNameTH $lastNameTH");
        print("Name (English): $titleEN $firstNameEN $lastNameEN");
        print("House Number: $houseNumber");
        print("Village: $village");
        print("Sub-District: $subDistrict");
        print("District: $district");
        print("Province: $province");
        print("Address Type: $addressType");
        print("Birth Date: $birthDate");
        print("Address: $address");
        print("Issue Date: $issueDate");
        print("Expire Date: $expireDate");
        print("Personal Number: $personalNumber");
        idCardNumber = idCardNumbe = x[0];
        print(text);
      }
      // print("ID Card Number: $idCardNumber");

      if (returnCode != NA_SUCCESS) {
        setState(() {
          textResult = checkException(returnCode);
          isEnabled = true;
        });
        // ===================== Disconnect Card ======================== //
        await disconnectCardDF();
        return;
      }

      text += "\n\nRead Text: " + readTextTime.toStringAsFixed(2) + " s";

      setState(() {
        // print("ID Card Number: $idCardNumber");
        textResult = text;
        _textController.text = idCardNumber;
      });

      // ===================== Get Photo ======================== //
      var parts2 = await getPhotoDF();

      if (parts == null)
        returnCode = NA_GET_PHOTO_ERROR;
      else {
        returnCode = int.parse(parts2[0].trim());
        text = parts2[1].trim();
      }

      if (returnCode != NA_SUCCESS) {
        if (textResult != checkException(returnCode)) {
          textResult = textResult + "\n" + checkException(returnCode);
        }
        setState(() {
          textResult = textResult;
          isEnabled = true;
        });

        // ===================== Disconnect Card ======================== //
        await disconnectCardDF();
        return;
      }

      String photo = parts2[1].trim();
      var resBytesPhoto = base64Decode(photo);

      setState(() {
        bytesPhoto = resBytesPhoto;
      });

      // ===================== Disconnect Card ======================== //
      await disconnectCardDF();
      endTime = new DateTime.now().millisecondsSinceEpoch;
      double readPhotoTime = ((endTime - startTime) / 1000);

      setState(() {
        textResult = textResult +
            "\nRead Text+Photo: " +
            readPhotoTime.toStringAsFixed(2) +
            " s";
        isEnabled = true;
      });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      setState(() {
        textResult = text;
        isEnabled = true;
      });
    }
  }

  //////////////////////////////// Button Get Card Status ////////////////////////////////
  Future<void> buttonGetCardStatus() async {
    String text = "Checking card in reader...";

    setState(() {
      isEnabled = false;
      bytesPhoto = bytesAppPhoto;
      textResult = text;
    });

    try {
      // ===================== Check Card Status ======================== //
      int returnCode =
          await getCardStatusDF(); // Call native method getCardStatusMC

      if (returnCode == 1) {
        text = "Card Status: Present";
      } else if (returnCode == -16) {
        text = "Card Status: Absent (card not found)";
      } else {
        text = checkException(returnCode);
        if (IO.Platform.isIOS) {
          if (isReaderConnected != true) {
            text = "-3 Reader not found.";
          }
        }
      }

      setState(() {
        isEnabled = true;
        textResult = text;
      });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
        isEnabled = true;
      });
    }
  }

  //////////////////////////////// Generate RID To String ////////////////////////////////
  Future<void> generateRIDToString() async {
    String readerID = "";
    String text = "";
    if (isReaderConnected == false) {
      setState(() {
        textResult = "";
        isEnabled = true;
      });
      return;
    }
    try {
      // ===================== Get RID ======================== //
      var parts = await getReaderIDDF();
      int returnCode = int.parse(parts[0].trim());
      if (returnCode > 0) {
        int numberBytes = returnCode;
        String base64Rid = parts[1].trim();
        late Uint8List byteRid = base64Decode(base64Rid);
        String hexString = "";
        for (int i = 0; i < numberBytes; i++) {
          String h = byteRid[i].toRadixString(16); // Number to Hex String
          while (h.length < 2) {
            h = "0" + h;
          }
          hexString += h + " ";
        }
        readerID = hexString.toUpperCase();
        text = textResult + "\n\n" + "Reader ID: " + readerID;
      } else if (returnCode < 0) {
        text = textResult + "\n\n" + checkException(returnCode);
      }
      setState(() {
        textResult = text;
        isEnabled = true;
      });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
        isEnabled = true;
      });
    }
  }

  //////////////////////////////// Get File Directory ////////////////////////////////
  Future<void> getFilesDirDF() async {
    try {
      String sFilesDirectory = await platform
          .invokeMethod('getFilesDirMC'); // Call native method getFilesDirMC
      rootFolder = sFilesDirectory +
          folder; // you can change path of license files at here
      sLicFile = rootFolder + sLICFileName;
      parameterOpenLib = sLicFile;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
      });
    }
  }

  //////////////////////////////// Generate Photo to UI ////////////////////////////////
  Future<void> setAppLogo() async {
    try {
      ByteData data = await rootBundle.load(
          'assets/flutter_logo.png'); // you can set assets path at pubspec.yaml
      bytesAppPhoto =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      setState(() {
        bytesPhoto = bytesAppPhoto;
        isVisible = true;
      });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      setState(() {
        isVisible = true;
        textResult = text;
      });
    }
  }

  //////////////////////////////// Set Listener ////////////////////////////////
  Future<bool> setListenerDF() async {
    try {
      int returnCode = await platform
          .invokeMethod('setListenerMC'); // Call native method setListenerMC
      if (returnCode == NA_SUCCESS) {
        return true;
      } else {
        setState(() {
          textResult = this.checkException(returnCode);
        });
        return false;
      }
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
      });
      return false;
    }
  }

  //////////////////////////////// Request Permission Function ////////////////////////////////
  void requestPermission() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    } else {
      await Permission.location.request();

      if (await Permission.location.isDenied) {
        textResult = textResult + "\n\n" + '-32 Location permission error.';
      }
    }

    setState(() {
      textResult = textResult;
    });
  }

  //////////////////////////////// Write File Function ////////////////////////////////
  Future<bool> writeLicFileDF() async {
    String text = "";
    try {
      int returnCode = await platform.invokeMethod(
          'writeLicFileMC', sLicFile); // Call native method writeLicFileMC

      if (returnCode == 1) {
        text = "License file is already has been.";

        setState(() {
          textResult = text;
        });
        return true;
      } else if (returnCode != 0) {
        text = "Write License file failed.";
        setState(() {
          textResult = text;
        });
        return false;
      } else {
        return true;
      }
    } on PlatformException catch (e) {
      text += "\n" + "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
      });
      return false;
    }
  }

  //////////////////////////////// Set Permission ////////////////////////////////
  Future<bool> setPermissionsDF() async {
    try {
      int pms = 1;
      int returnCode = await platform.invokeMethod(
          'setPermissionsMC', pms); // Call native method setPermissionsMC
      if (returnCode < 0) {
        setState(() {
          textResult = checkException(returnCode);
        });
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      String result = "\n" + "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = result;
      });
      return false;
    }
  }

  //////////////////////////////// Open Lib ////////////////////////////////
  Future<bool> openLibDF() async {
    String text = "";
    try {
      int returnCode = await platform.invokeMethod(
          'openLibMC', parameterOpenLib); // Call native method openLibMC
      if (returnCode == 0) {
        text = text + "\n" + "Opened the library successfully.";
        setState(() {
          textResult = text;
          readerName = 'Reader: ';
        });
        return true;
      } else {
        text = "Opened the library failed, Please restart app.";
        setState(() {
          textResult = text;
          readerName = 'Reader: ';
        });
        return false;
      }
    } on PlatformException catch (e) {
      text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
        readerName = 'Reader: ';
      });
      return false;
    }
  }

  //////////////////////////////// get Reader List ////////////////////////////////
  Future<dynamic> getReaderListDF() async {
    var result;

    try {
      if (IO.Platform.isAndroid) {
        int listOption = NA_POPUP +
            NA_SCAN +
            NA_BLE1 +
            NA_BLE0 +
            NA_BT +
            NA_USB; // 0x9F USB & BLE1 & BLE0 &  BT Reader
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        var sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 31) {
          if ((listOption & NA_SCAN) != 0 &&
              ((listOption & NA_BT) != 0 ||
                  (listOption & NA_BLE1) != 0 ||
                  (listOption & NA_BLE0) != 0)) {
            var isBluetoothScan = await Permission.bluetoothScan.request();
            var isBluetoothConnected =
                await Permission.bluetoothConnect.request();
            if (isBluetoothScan != PermissionStatus.granted &&
                isBluetoothConnected != PermissionStatus.granted) {
              listOption = listOption -
                  (NA_SCAN +
                      NA_BLE1 +
                      NA_BLE0 +
                      NA_BT); //remove BLE0, BT Scanning
            }
          }
        } else {
          if ((listOption & NA_SCAN) != 0 &&
              ((listOption & NA_BT) != 0 ||
                  (listOption & NA_BLE1) != 0 ||
                  (listOption & NA_BLE0) != 0)) {
            var isLocationDenied = await Permission.location.status.isDenied;
            if (isLocationDenied) {
              listOption = listOption -
                  (NA_SCAN +
                      NA_BLE1 +
                      NA_BLE0 +
                      NA_BT); //remove BLE0, BT Scanning
            }
          }
        }

        result = await platform.invokeMethod('getReaderListMC',
            listOption); // Call native method getReaderListMC
      } else if (IO.Platform.isIOS) {
        result = await platform.invokeMethod(
            'getReaderListMC'); // Call native method getReaderListMC
      }
      var parts = result.split(';');
      return parts;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      setState(() {
        textResult = text;
        isEnabled = true;
      });
      return null;
    }
  }

  //////////////////////////////// Select Reader ////////////////////////////////
  Future<bool> selectReaderDF(String textReaderName) async {
    try {
      int returnCode = await platform.invokeMethod('selectReaderMC',
          textReaderName); // Call native method selectReaderMC

      if (returnCode != NA_SUCCESS) {
        setState(() {
          textResult = checkException(returnCode);
        });

        if (returnCode != NA_INVALID_LICENSE &&
            returnCode != NA_LICENSE_FILE_ERROR) {
          setState(() {
            isEnabled = true;
            readerName = 'Reader: ';
          });
        } else if (returnCode == NA_INVALID_LICENSE ||
            returnCode == NA_LICENSE_FILE_ERROR) {
          setState(() {
            isEnabled = true;
            readerName = 'Reader: ' + textReaderName;
          });
        }

        return false;
      } else if (returnCode == NA_SUCCESS) {
        isReaderConnected = true;
        setState(() {
          readerName = 'Reader: ' + textReaderName;
        });
      }
      return true;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      setState(() {
        textResult = text;
        isEnabled = true;
      });
      return false;
    }
  }

  //////////////////////////////// Get Reader Info ////////////////////////////////
  Future<void> getReaderInfoDF() async {
    String readerInfo = "";
    if (isReaderConnected == false) {
      setState(() {
        textResult = "";
        isEnabled = true;
      });
      return;
    }
    try {
      var result = await platform.invokeMethod(
          'getReaderInfoMC'); // Call native method getReaderInfoMC
      var parts = result.split(';');
      int returnCode = int.parse(parts[0].trim());
      if (returnCode == NA_SUCCESS) {
        readerInfo = parts[1].trim();
        result = "Reader Info: " + readerInfo;
      } else {
        result = checkException(returnCode);
      }
      setState(() {
        textResult = result;
      });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
      });
    }
  }

  //////////////////////////////// Connect Card ////////////////////////////////
  Future<int> connectCardDF() async {
    try {
      int returnCode = await platform
          .invokeMethod('connectCardMC'); // Call native method connectCardMC
      return returnCode;
    } on PlatformException {
      return NA_CONNECTION_ERROR;
    }
  }

  //////////////////////////////// Get NID Number ////////////////////////////////
  Future<dynamic> getNIDNumberDF() async {
    try {
      String result = await platform
          .invokeMethod('getNIDNumberMC'); // Call native method getNIDNumberMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Text ////////////////////////////////
  Future<dynamic> getTextDF() async {
    try {
      String result = await platform
          .invokeMethod('getTextMC'); // Call native method getTextMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Photo ////////////////////////////////
  Future<dynamic> getPhotoDF() async {
    try {
      String result = await platform
          .invokeMethod('getPhotoMC'); // Call native method getPhotoMC

      var parts = result.split(';');

      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Disconnect Card ////////////////////////////////
  Future<int> disconnectCardDF() async {
    try {
      int returnCode = await platform.invokeMethod(
          'disconnectCardMC'); // Call native method disconnectCardMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////////// Deselect Reader ////////////////////////////////////
  Future<int> deselectReaderDF() async {
    try {
      int returnCode = await platform.invokeMethod(
          'deselectReaderMC'); // Call native method deselectReaderMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

//////////////////////////// Get Card Status ////////////////////////////////
  Future<int> getCardStatusDF() async {
    try {
      int returnCode = await platform.invokeMethod(
          'getCardStatusMC'); // Call native method getCardStatusMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////// Get RID ////////////////////////////////
  Future<dynamic> getReaderIDDF() async {
    try {
      String result = await platform
          .invokeMethod('getReaderIDMC'); // Call native method getReaderIDMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Software Info ////////////////////////////////
  Future<bool> getSoftwareInfoDF() async {
    String text = "";
    try {
      text = await platform.invokeMethod(
          'getSoftwareInfoMC'); // Call native method getSoftwareInfoMC
      setState(() {
        sSoftwareInfo = text;
      });
      return true;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      setState(() {
        textResult = text;
      });
      return false;
    }
  }

  //////////////////////////////// Get License Info ////////////////////////////////
  Future<bool> getLicenseInfoDF() async {
    String result = "";
    try {
      result = await platform.invokeMethod(
          'getLicenseInfoMC'); // Call native method getLicenseInfoMC
      setState(() {
        sLicenseInfo = result;
      });
      return true;
    } on PlatformException {
      setState(() {});
      return false;
    }
  }

  //////////////////////////////////// Close Lib ////////////////////////////////////
  Future<int> closeLibDF() async {
    try {
      int returnCode = await platform
          .invokeMethod('closeLibMC'); // Call native method closeLibMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////////// Exception ////////////////////////////////////
  String checkException(int returnCode) {
    if (returnCode == NA_INTERNAL_ERROR) {
      return "-1 Internal error.";
    } else if (returnCode == NA_INVALID_LICENSE) {
      return "-2 This reader is not licensed.";
    } else if (returnCode == NA_READER_NOT_FOUND) {
      return "-3 Reader not found.";
    } else if (returnCode == NA_CONNECTION_ERROR) {
      return "-4 Card connection error.";
    } else if (returnCode == NA_GET_PHOTO_ERROR) {
      return "-5 Get photo error.";
    } else if (returnCode == NA_GET_TEXT_ERROR) {
      return "-6 Get text error.";
    } else if (returnCode == NA_INVALID_CARD) {
      return "-7 Invalid card.";
    } else if (returnCode == NA_UNKNOWN_CARD_VERSION) {
      return "-8 Unknown card version.";
    } else if (returnCode == NA_DISCONNECTION_ERROR) {
      return "-9 Disconnection error.";
    } else if (returnCode == NA_INIT_ERROR) {
      return "-10 Init error.";
    } else if (returnCode == NA_READER_NOT_SUPPORTED) {
      return "-11 Reader not supported.";
    } else if (returnCode == NA_LICENSE_FILE_ERROR) {
      return "-12 License file error.";
    } else if (returnCode == NA_PARAMETERS_ERROR) {
      return "-13 Parameter error.";
    } else if (returnCode == NA_INTERNET_ERROR) {
      return "-15 Internet error.";
    } else if (returnCode == NA_CARD_NOT_FOUND) {
      return "-16 Card not found.";
    } else if (returnCode == NA_BLUETOOTH_DISABLED) {
      return "-17 Bluetooth is disabled.";
    } else if (returnCode == NA_LICENSE_UPDATE_ERROR) {
      return "-18 License update error.";
    } else if (returnCode == NA_STORAGE_PERMISSION_ERROR) {
      return "-31 Storage permission error.";
    } else if (returnCode == NA_LOCATION_PERMISSION_ERROR) {
      return "-32 Location permission error.";
    } else if (returnCode == NA_BLUETOOTH_PERMISSION_ERROR) {
      return "-33 Bluetooth permission error.";
    } else if (returnCode == NA_LOCATION_SERVICE_ERROR) {
      return "-41 Location service error.";
    } else {
      return returnCode.toString();
    }
  }

  ///////////////////////////////// Response from native /////////////////////////////////
  Future<void> _fromNative(MethodCall call) async {
    if (call.method == 'callTestResuls') {
      print('callTest result = ${call.arguments}');
    }
  }

  ///////////////////////////////// Exit App /////////////////////////////////
  Future<void> exitApp() {
    deselectReaderDF();
    closeLibDF();
    exit(0);
  }

  ///////////////////////////////////////// UI /////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text("$sAppName"),
          ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _textController, // กำหนด TextEditingController
                decoration: InputDecoration(
                  hintText: 'ลงชื่อ',
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
              child: new ElevatedButton(
                key: new Key('bt01'),
                onPressed: isEnabled ? () => buttonFindReader() : null,

                //color: Colors.grey[600],
                //disabledColor: Colors.grey[400],
                style: ElevatedButton.styleFrom(primary: Colors.grey[600]
                    //onSurface: Colors.grey[400],
                    //fixedSize: Size.fromHeight(43)
                    ),
                child: new Text(
                  "Find Reader",
                  style: new TextStyle(
                      fontSize: 18.0,
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontFamily: "Roboto"),
                ),
              ),
            ),
            SizedBox(
              height: 4.0,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
              child: new ElevatedButton(
                key: new Key('bt02'),
                onPressed: isEnabled ? () => buttonRead() : null,
                //color: Colors.grey[600],
                //disabledColor: Colors.grey[400],
                style: ElevatedButton.styleFrom(primary: Colors.grey[600]
                    //onSurface: Colors.grey[400],
                    //fixedSize: Size.fromHeight(43)
                    ),
                child: new Text(
                  "Read",
                  style: new TextStyle(
                      fontSize: 18.0,
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontFamily: "Roboto"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
