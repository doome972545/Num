import UIKit
import Flutter

// NAiFlutter
// Copyright R&D Computer System Co., Ltd.

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate ,ReaderInterfaceDelegate  {
    
    func readerInterfaceDidChange(_ attached: Bool) {
        
    }
    
    func cardInterfaceDidDetach(_ attached: Bool) {
        
    }
    
    
    private var flutterResult: FlutterResult? = nil
    
    let VL_OPENLIB_MODE=0
    let FLVL_OPENLIB_MODE=1
    
    fileprivate var mNiOS : NiOS?
    private var myObject : NiOS?
    private var mReaderFtInterface : ReaderInterface?
    
    fileprivate var Parameter_OpenLib: String?
    
    fileprivate var readerSelect: String?
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // create nid object for interfacing with smartcard reader
        mNiOS = NiOS()
        
        mReaderFtInterface = ReaderInterface();
        mReaderFtInterface?.setDelegate(self);
        
        
        let controller = (window?.rootViewController as! FlutterViewController)
        
        let methodChannel =
            FlutterMethodChannel(name: "flutter.native/helper", binaryMessenger: controller.binaryMessenger)
        

// ============================= Method Channel Function ============================= //
        methodChannel
            .setMethodCallHandler({ [weak self](call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                
                self?.flutterResult = result
                
                if(call.method == "getFilesDirMC"){
                    
                    var libpath :[ String];
                    var path: String;
                    libpath = NSSearchPathForDirectoriesInDomains( FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true);
                    
                    path = libpath[0]+"";
                    
                    self?.flutterResult?(path);
                }
                
                if(call.method == "openLibMC"){
                    
                    self?.Parameter_OpenLib = call.arguments as? String;
                            
                    Thread.detachNewThreadSelector(#selector(self?.OpenLibraryThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getReaderListMC"){
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        Thread.detachNewThreadSelector(#selector(self?.GetReaderListThread), toTarget: self as Any, with: nil)
                    })
                    
                    
                }
                
                if(call.method == "selectReaderMC"){
                    
                    self?.readerSelect = call.arguments as? String;
                            
                    Thread.detachNewThreadSelector(#selector(self?.SelectReaderThread), toTarget: self as Any, with: nil)
                
                }
                
                if(call.method == "getReaderInfoMC"){
                    
                    Thread.detachNewThreadSelector(#selector(self?.GetReaderInfoThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getReaderIDMC"){
                
                    Thread.detachNewThreadSelector(#selector(self?.GetReaderIDThread), toTarget: self as Any, with: nil)
           
                }
                
                if(call.method == "connectCardMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.ConnectCardThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "disconnectCardMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.DisconnectCardThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getTextMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.GetTextThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getPhotoMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.GetPhotoThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getNIDNumberMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.GetNIDNumberThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "updateLicenseFileMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.UpdateLicenseFileThread), toTarget: self as Any, with: nil)
                    
                }
            
                
                if(call.method == "getCardStatusMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.GetCardStatusThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "deselectReaderMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.DeselectReaderThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "closeLibMC"){
 
                    Thread.detachNewThreadSelector(#selector(self?.CloseLibThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getLicenseInfoMC"){
          
                    Thread.detachNewThreadSelector(#selector(self?.GetLicenseInfoThread), toTarget: self as Any, with: nil)
                    
                }
                
                if(call.method == "getSoftwareInfoMC"){
            
                    Thread.detachNewThreadSelector(#selector(self?.GetSoftwareInfoThread), toTarget: self as Any, with: nil)
                
                }
                
            })
// =================================================================================== //
            
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
    
    
    
    

// =============================  Multithreading Function ============================= //
    
    @objc func OpenLibraryThread() {
        
        var LICpath  : NSMutableString
        LICpath =  self.Parameter_OpenLib!.mutableCopy() as! NSMutableString;
        
        var res :Int32?;
        res = mNiOS?.openLibNi(LICpath)
        
        if res != 0 {
            if(res == NI_LICENSE_FILE_ERROR /*-12*/) {
                //FLVL_OPENLIB_MODE
                res = mNiOS?.updateLicenseFileNi()
                
            }
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func GetReaderListThread() {
        
        var str_result :String?;
        let readerList :NSMutableArray=NSMutableArray();
        var res :Int32?;
        res =  mNiOS?.getReaderListNi(readerList);
        
        str_result = String( format: "%d;" , res!);
        
        if(res > 0){
            str_result = String( format: "%d;%@" ,res! , readerList[0] as! String );
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
        
    }
    
    @objc func SelectReaderThread() {
        
        var res :Int32?;
        res = mNiOS?.selectReaderNi( self.readerSelect as? NSMutableString);
    
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
       
    }
    
    @objc func GetReaderInfoThread() {
        
        var str_result :String?;
        let nsData = NSMutableString.init()
        let res : Int32 = (mNiOS?.getReaderInfoNi(nsData))!
        
        if res != 0 {
            str_result = String(format: "%d;"  , NI_READER_NOT_FOUND)
        }else{
            str_result = String(format: "%d;%@" , NI_SUCCESS, nsData )
        }

        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
        
    }
    
    @objc func GetReaderIDThread() {
        
        var str_result :String?;
        let  RIDBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        RIDBuffer.initialize(to: 0)
        let iRetRidNi = mNiOS?.getRidNi( RIDBuffer)
        if(iRetRidNi==16) {
            
            var strFTlib: [UInt8] = []
            
            for i in 0..<16 {
                strFTlib.append(UInt8( RIDBuffer[i] ))
            }
            
            let data = NSData(bytes: strFTlib, length: strFTlib.count)
            
            let encoded = data.base64EncodedString()
            
            str_result =  String(format: "%d;%@" , iRetRidNi!, encoded )
        }
        else {
            str_result = String(format: "%d;",iRetRidNi!)
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
    }
    
    @objc func ConnectCardThread() {

        let res : Int32?;
        res = mNiOS?.connectCardNi();
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func DisconnectCardThread() {

        let res : Int32?;
        res = mNiOS?.disconnectCardNi();
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    
    @objc func GetTextThread() {
        
        var str_result :String?;
        let res : Int32?;
        let nsData: NSMutableString = NSMutableString()
        //res = mNiOS?.getATextNi(nsData)
        res = mNiOS?.getNIDTextNi(nsData)
        
        str_result = String(format: "%d;%@",res!,nsData)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
        
    }
    
    @objc func GetPhotoThread() {
        
        var str_result :String?;
        let res : Int32?;
        let dataPhoto = NSMutableData.init();
        res = mNiOS?.getNIDPhotoNi(dataPhoto)
        
        let encoded = dataPhoto.base64EncodedString()
        
        str_result = String(format: "%d;%@",res!,encoded)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
        
    }
    
    @objc func GetNIDNumberThread() {
        
        var str_result :String?;
        let res : Int32?;
        let nsData: NSMutableString = NSMutableString()
        res = mNiOS?.getNIDNumberNi(nsData);
        
        str_result = String(format: "%d;%@",res!,nsData)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(str_result);
        })
        
    }
    
    @objc func UpdateLicenseFileThread() {
        
        var res : Int32?;
        res = mNiOS?.updateLicenseFileNi();
        
        if(res == NI_LICENSE_UPDATE_ERROR){
            res = mNiOS?.updateLicenseFileNi();
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func GetCardStatusThread() {
        
        let res : Int32?;
        res = mNiOS?.getCardStatusNi()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func DeselectReaderThread() {
        
        let res : Int32?;
        res = mNiOS?.deselectReaderNi();
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func CloseLibThread() {
        
        let res : Int32?;
        res = mNiOS?.closeLibNi();
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(res);
        })
        
    }
    
    @objc func GetLicenseInfoThread() {
        
        var _ :[ String];
        let Lic = NSMutableString.init();
        
        _ = mNiOS?.getLicenseInfoNi(Lic);
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(Lic)
        })
        
    }
    
    @objc func GetSoftwareInfoThread() {
        
        let sInfo = NSMutableString.init();
        _ = mNiOS?.getSoftwareInfoNi(sInfo)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.flutterResult?(sInfo);
        })
        
    }
// ==================================================================================== //
    
    
    
    
    func _getFTDevVer(hContext: UInt32, firmware:inout String , hardware:inout String ) -> Int {
        
        var iRet: Int
        firmware = "";
        hardware = "";
        
        let firmwareRevision = UnsafeMutablePointer<Int8>.allocate(capacity: 100)
        firmwareRevision.initialize(to: 0)
        
        let hardwareRevision = UnsafeMutablePointer<Int8>.allocate(capacity: 100)
        hardwareRevision.initialize(to: 0)
        
        
        iRet = Int(FtGetDevVer( SCARDCONTEXT((hContext)), firmwareRevision, hardwareRevision))
        if(iRet==0)
        {
            firmware = String(validatingUTF8: UnsafePointer<CChar>(firmwareRevision))!
            hardware = String(validatingUTF8: UnsafePointer<CChar>(hardwareRevision))!
        }
        
        return iRet
    }
    
    func _getFTSerialNum(SN:inout String  ) -> Int {
        var iRet: Int
        SN = "";
        
        let  buf = UnsafeMutablePointer<Int8>.allocate(capacity: 200)
        buf.initialize(to: 0)
        iRet = Int( FtGetSerialNum(0,100, buf) );
        if( iRet == 0)
        {
            SN = String(validatingUTF8: UnsafePointer<CChar>(buf))!
        }
        return iRet
    }
    
    
    
}
