//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class InitKeyBundle: NSObject, NSSecureCoding {

    private static let kCoderPKBIdentityKey           = "kCoderPKBIdentityKey";
    private static let kCoderPKBregistrationId        = "kCoderPKBregistrationId";
    private static let kCoderPKBdeviceId              = "kCoderPKBdeviceId";
    private static let kCoderPKBsignedInitKeyPublic    = "kCoderPKBsignedInitKeyPublic";
    private static let kCoderPKBinitKeyPublic          = "kCoderPKBinitKeyPublic";
    private static let kCoderPKBinitKeyId              = "kCoderPKBinitKeyId";
    private static let kCoderPKBsignedInitKeyId        = "kCoderPKBsignedInitKeyId";
    private static let kCoderPKBsignedInitKeySignature = "kCoderPKBsignedInitKeySignature";
    
    private(set) public var identityKey: Data
    private(set) public var registrationId: String
    private(set) public var deviceId: String
    private(set) public var signedInitKeyPublic: Data
    private(set) public var initKeyPublic: Data
    private(set) public var initKeyId: Int
    private(set) public var signedInitKeyId: String
    private(set) public var signedInitKeySignature: Data
    
    public init(registrationId: String, deviceId: String, initKeyId: Int, initKeyPublic: Data, signedInitKeyPublic: Data, signedInitKeyId: String, signedInitKeySignature: Data, identityKey: Data) {
        self.identityKey = identityKey
        self.registrationId = registrationId
        self.deviceId = deviceId
        self.signedInitKeyPublic = signedInitKeyPublic
        self.signedInitKeyId = signedInitKeyId
        self.initKeyPublic = initKeyPublic
        self.initKeyId = initKeyId
        self.signedInitKeyId = signedInitKeyId
        self.signedInitKeySignature = signedInitKeySignature
    }
    
    //MARK: - NSSecureCoding
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard   let initKeyPublic = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBinitKeyPublic) as? Data,
                let signedInitKeyPublic = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBsignedInitKeyPublic) as? Data,
                let signedInitKeySignature = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBsignedInitKeySignature) as? Data,
                let identityKey = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBIdentityKey) as? Data,
                let registrationId = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBregistrationId) as? String,
                let deviceId = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBdeviceId) as? String,
                let signedInitKeyId = aDecoder.decodeObject(forKey: InitKeyBundle.kCoderPKBsignedInitKeyId) as? String
        else {
                return nil
        }
        
        self.init(registrationId: registrationId,
                  deviceId: deviceId,
                  initKeyId: aDecoder.decodeInteger(forKey: InitKeyBundle.kCoderPKBinitKeyId),
                  initKeyPublic: initKeyPublic,
                  signedInitKeyPublic: signedInitKeyPublic,
                  signedInitKeyId: signedInitKeyId,
                  signedInitKeySignature: signedInitKeySignature,
                  identityKey: identityKey)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(registrationId, forKey: InitKeyBundle.kCoderPKBregistrationId)
        aCoder.encode(deviceId, forKey: InitKeyBundle.kCoderPKBdeviceId)
        aCoder.encode(initKeyId, forKey: InitKeyBundle.kCoderPKBinitKeyId)
        aCoder.encode(signedInitKeyId, forKey: InitKeyBundle.kCoderPKBsignedInitKeyId)
        
        aCoder.encode(initKeyPublic, forKey: InitKeyBundle.kCoderPKBinitKeyPublic)
        aCoder.encode(signedInitKeyPublic, forKey: InitKeyBundle.kCoderPKBsignedInitKeyPublic)
        aCoder.encode(signedInitKeySignature, forKey: InitKeyBundle.kCoderPKBsignedInitKeySignature)
        aCoder.encode(identityKey, forKey: InitKeyBundle.kCoderPKBIdentityKey)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}
