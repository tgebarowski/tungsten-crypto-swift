//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class PendingInitKey: NSObject, NSSecureCoding {
    
    private static let kCoderInitKeyId = "kCoderInitKeyId"
    private static let kCoderSignedInitKeyId = "kCoderSignedInitKeyId"
    private static let kCoderBaseKey = "kCoderBaseKey"
    
    private(set) public var initKeyId: Int
    private(set) public var signedInitKeyId: String
    private(set) public var baseKey: Data
    
    public init(baseKey: Data, initKeyId: Int, signedInitKeyId: String) {
        self.baseKey = baseKey
        self.initKeyId = initKeyId
        self.signedInitKeyId = signedInitKeyId
    }
    
    //MARK: - NSSecureCoding
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let baseKey = aDecoder.decodeObject(forKey: PendingInitKey.kCoderBaseKey) as? Data,
        let signedInitKeyId = aDecoder.decodeObject(forKey: PendingInitKey.kCoderSignedInitKeyId) as? String
        
        else {
            return nil
        }
        
        self.init(baseKey: baseKey,
                  initKeyId: aDecoder.decodeInteger(forKey: PendingInitKey.kCoderInitKeyId),
                  signedInitKeyId: signedInitKeyId)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(baseKey, forKey: PendingInitKey.kCoderBaseKey)
        aCoder.encode(initKeyId, forKey: PendingInitKey.kCoderInitKeyId)
        aCoder.encode(signedInitKeyId, forKey: PendingInitKey.kCoderSignedInitKeyId)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}

