//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class CryptoInitKeysBundle: NSObject {
    
    private(set) public var signedInitKeyId: String
    private(set) public var deviceId: String
    private(set) public var userId: String
    private(set) public var signedInitKeyPublic: Data
    private(set) public var signedInitKeySignature: Data
    private(set) public var identityKey: Data
    private(set) public var initKeys: [CryptoPublicInitKey]
    
    public init(signedInitKeyId: String, deviceId: String, userId: String, signedInitKeyPublic: Data, signedInitKeySignature: Data, identityKey: Data, initKeys: [CryptoPublicInitKey]) {
        self.signedInitKeyId = signedInitKeyId
        self.deviceId = deviceId
        self.userId = userId
        self.signedInitKeyPublic = signedInitKeyPublic
        self.signedInitKeySignature = signedInitKeySignature
        self.identityKey = identityKey
        self.initKeys = initKeys
    }
    
    public override var debugDescription: String {
        
        var description = String(format: "<%@: %lu> Signed initKey id: %lu; device id: %lu; user id: %@", NSStringFromClass(object_getClass(self)), unsafeBitCast(self, to: Int.self), self.signedInitKeyId, self.deviceId, self.userId)
            description.append(String(format: "\nIdentity key: %@", self.identityKey as NSData))
            description.append(String(format: "\nSigned initKey public: %@", self.signedInitKeyPublic as NSData))
            description.append(String(format: "\nSigned initKey signature: %@", self.signedInitKeySignature as NSData))
            description.append(String(format: "\nInitKeys: "))

        for initKey in self.initKeys {
            description.append(String(format: "\n InitKey with ID %lu; public key:%@", initKey.identifier, initKey.publicKey as NSData))
        }
        
        return description
    }
}
