//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class DerivedSecrets: NSObject {
    
    private(set) public var cipherKey: Data
    private(set) public var macKey: Data
    private(set) public var iv: Data
    
    public init(cipherKey: Data, macKey: Data, iv: Data) {
        self.cipherKey = cipherKey
        self.macKey = macKey
        self.iv = iv
    }
    
    public class func derivedInitialSecrets(with masterKey: Data) throws -> DerivedSecrets {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        
        guard let info = "'MG[~E3$V;nYHWnY".data(using: .utf8) else {
            fatalError("Unable to generate data from string")
        }
        
        return try keyDerivation.deriveKey(seed: masterKey, info: info, salt: Data(bytes: [0,0,0,0]))
    }
    
    public class func derivedCoreedSecretsWithSharedSecret(with sharedSecret: Data, rootKey: Data) throws -> DerivedSecrets {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        
        guard let info = "C%wmk9UM~S%wAM5;".data(using: .utf8) else {
            fatalError("Unable to generate data from string")
        }
        
        return try keyDerivation.deriveKey(seed: sharedSecret, info: info, salt: rootKey)
    }
    
    public class func derivedMessageKeys(with data: Data) throws -> DerivedSecrets {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        
        
        guard let info = "m#M6A@BkLc]aG{QN".data(using: .utf8) else {
            fatalError("Unable to generate data from string")
        }
        
        return try keyDerivation.deriveKey(seed: data, info: info, salt: Data(bytes: [0,0,0,0]))
    }
}
