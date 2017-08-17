//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class InitKeyRecord: NSObject, NSSecureCoding {
    
    private static let kCoderInitKeyId = "kCoderInitKeyId"
    private static let kCoderInitKeyPair = "kCoderInitKeyPair"
    
    private(set) public var id: Int
    private(set) public var keyPair: KeyPair

    public init(id: Int, keyPair: KeyPair) {
        self.id = id
        self.keyPair = keyPair
    }
    
    //MARK: - NSSecureCoding
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let keyPair = aDecoder.decodeObject(forKey: InitKeyRecord.kCoderInitKeyPair) as? KeyPair else {
            return nil
        }
        
        self.init(id: aDecoder.decodeInteger(forKey: InitKeyRecord.kCoderInitKeyId),
                  keyPair: keyPair)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: InitKeyRecord.kCoderInitKeyId)
        aCoder.encode(keyPair, forKey: InitKeyRecord.kCoderInitKeyPair)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}
