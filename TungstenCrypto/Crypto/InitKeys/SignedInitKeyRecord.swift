//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SignedInitKeyRecord: NSObject, NSSecureCoding {
    
    private static let kCoderInitKeyId = "kCoderInitKeyId"
    private static let kCoderInitKeyPair = "kCoderInitKeyPair"
    private static let kCoderInitKeyDate      = "kCoderInitKeyDate";
    private static let kCoderInitKeySignature = "kCoderInitKeySignature"
    
    private(set) public var id: String
    private(set) public var keyPair: KeyPair
    private(set) public var signature: Data
    private(set) public var generatedAt: Date
    
    public init(id: String, keyPair: KeyPair, signature: Data, generatedAt: Date) {
        self.id = id
        self.keyPair = keyPair
        self.signature = signature
        self.generatedAt = generatedAt
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: SignedInitKeyRecord.kCoderInitKeyId) as? String,
            let keyPair = aDecoder.decodeObject(forKey: SignedInitKeyRecord.kCoderInitKeyPair) as? KeyPair,
            let date = aDecoder.decodeObject(forKey: SignedInitKeyRecord.kCoderInitKeyDate) as? Date,
            let signature = aDecoder.decodeObject(forKey: SignedInitKeyRecord.kCoderInitKeySignature) as? Data else {
                return nil
        }
        
        self.init(id: id,
                  keyPair: keyPair,
                  signature: signature,
                  generatedAt: date)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(signature, forKey: SignedInitKeyRecord.kCoderInitKeySignature)
        aCoder.encode(generatedAt, forKey: SignedInitKeyRecord.kCoderInitKeyDate)
        aCoder.encode(id, forKey: SignedInitKeyRecord.kCoderInitKeyId)
        aCoder.encode(keyPair, forKey: SignedInitKeyRecord.kCoderInitKeyPair)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}
