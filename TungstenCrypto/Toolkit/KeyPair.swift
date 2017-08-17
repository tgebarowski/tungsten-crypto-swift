//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class KeyPair: NSObject, NSSecureCoding {
    
    private static let kKeyPairPublicKey = "kKeyPairPublicKey"
    private static let kKeyPairPrivateKey = "kKeyPairPrivateKey"
    
    private(set) public var publicKey: Data
    internal(set) public var privateKey: Data
    
    public init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }
    
    //MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let privateKey = aDecoder.decodeObject(forKey: KeyPair.kKeyPairPrivateKey) as? Data,
            let publicKey = aDecoder.decodeObject(forKey: KeyPair.kKeyPairPublicKey) as? Data else {
                return nil
        }
        
        self.init(privateKey: privateKey, publicKey: publicKey)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(privateKey, forKey: KeyPair.kKeyPairPrivateKey)
        aCoder.encode(publicKey, forKey: KeyPair.kKeyPairPublicKey)
    }
}
