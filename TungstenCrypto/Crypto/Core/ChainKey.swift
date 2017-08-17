//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class ChainKey: NSObject, NSSecureCoding {
    
    private(set) public var index: Int
    private(set) public var key: Data
    
    private let chainKeySeed = Data(bytes: [0x02])
    private let messageKeySeed = Data(bytes: [0x01])
    
    public init(key: Data, index: Int) {
        self.key = key
        self.index = index
    }
    
    public func next() -> ChainKey {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        let nextCK = keyDerivation.hmac(seed: chainKeySeed, key: key)
        
        return ChainKey(key: nextCK, index: index+1)
    }
    
    public func messageKeys() throws -> MessageKeys {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        let messageHmac = keyDerivation.hmac(seed: messageKeySeed, key: key)
        let derivedSecrets = try DerivedSecrets.derivedMessageKeys(with: messageHmac)
        
        return MessageKeys(cipherKey: derivedSecrets.cipherKey, macKey: derivedSecrets.macKey, iv: derivedSecrets.iv, index: index)
    }
    
    //MARK: - NSSecureCoding
    
    private static let kCoderKey = "kCoderKey";
    private static let kCoderIndex = "kCoderIndex";
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let key = aDecoder.decodeObject(forKey: ChainKey.kCoderKey) as? Data else {
            return nil
        }
        
        self.init(key: key, index: aDecoder.decodeInteger(forKey: ChainKey.kCoderIndex))
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(key, forKey: ChainKey.kCoderKey)
        aCoder.encode(index, forKey: ChainKey.kCoderIndex)
    }
}
