//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class RootKey: NSObject, NSSecureCoding {
    
    private(set) public var keyData: Data
    
    public init(data: Data) {
        self.keyData = data
    }
    
    public func createChain(theirEphemeral: Data, ourEphemeral: KeyPair) throws -> RKCK {
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement 
        
        let sharedSecret: Data = try keyAgreement.sharedSecred(from: theirEphemeral, keyPair: ourEphemeral)
        let secrets = try DerivedSecrets.derivedCoreedSecretsWithSharedSecret(with: sharedSecret, rootKey: keyData)
        
        return RKCK(rootKey: RootKey(data: secrets.cipherKey),
                    chainKey: ChainKey(key: secrets.macKey, index: 0))
        
    }
    
    //MARK: - NSSecureCoding
    
    private static let kCoderData = "kCoderData";
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: RootKey.kCoderData) as? Data else {
            return nil
        }
        self.init(data: data)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(keyData, forKey: RootKey.kCoderData)
    }
}
