//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class MessageKeys: NSObject, NSSecureCoding {
    
    private(set) public var cipherKey: Data
    private(set) public var macKey: Data
    private(set) public var iv: Data
    private(set) public var index: Int
    
    public init(cipherKey: Data, macKey: Data, iv: Data, index: Int) {
        self.cipherKey = cipherKey
        self.macKey = macKey
        self.iv = iv
        self.index = index
    }
    
    public override var debugDescription: String {
        return String(format: "cipherKey: %@\n macKey %@\n", self.cipherKey.description, self.macKey.description)
    }
    
    //MARK: NSSecureCoding
    
    private static let kCoderMessageKeysCipherKey = "kCoderMessageKeysCipherKey"
    private static let kCoderMessageKeysMacKey    = "kCoderMessageKeysMacKey"
    private static let kCoderMessageKeysIVKey     = "kCoderMessageKeysIVKey"
    private static let kCoderMessageKeysIndex     = "kCoderMessageKeysIndex"
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let cipherKey = aDecoder.decodeObject(forKey: MessageKeys.kCoderMessageKeysCipherKey) as? Data,
        let macKey = aDecoder.decodeObject(forKey: MessageKeys.kCoderMessageKeysMacKey) as? Data,
            let iv = aDecoder.decodeObject(forKey: MessageKeys.kCoderMessageKeysIVKey) as? Data else {
                return nil
        }
        
        self.init(cipherKey: cipherKey, macKey: macKey, iv: iv, index: aDecoder.decodeInteger(forKey: MessageKeys.kCoderMessageKeysIndex))
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(cipherKey, forKey: MessageKeys.kCoderMessageKeysCipherKey)
        aCoder.encode(macKey, forKey: MessageKeys.kCoderMessageKeysMacKey)
        aCoder.encode(iv, forKey: MessageKeys.kCoderMessageKeysIVKey)
        aCoder.encode(index, forKey: MessageKeys.kCoderMessageKeysIndex)
    }
}

