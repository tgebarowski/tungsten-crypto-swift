//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class CryptoConfigurationBuilder: NSObject {
    
    private var keyAgreement: KeyAgreement
    private var symmetricCipher: SymmetricCipher
    private var logging: Logging?
    private var keyDerivation: KeyDerivation
    private var messageSerialization: MessageSerialization
    
    public override init() {
        keyAgreement = SodiumKeyAgreement()
        symmetricCipher = TUNAes256GcmCipher()
        logging = nil
        keyDerivation = HMACKDFKeyDerivation()
        messageSerialization = ProtobuffsMessageSerialization()
    }
    
    public func setKeyAgreement(_ keyAgreement: KeyAgreement) -> CryptoConfigurationBuilder {
        self.keyAgreement = keyAgreement
        return self
    }
    
    public func setSymmetricCipher(_ symmetricCipher: SymmetricCipher) -> CryptoConfigurationBuilder {
        self.symmetricCipher = symmetricCipher
        return self
    }
    
    public func setLogging(_ logging: Logging) -> CryptoConfigurationBuilder {
        self.logging = logging
        return self
    }
    
    public func setKeyDerivation(_ keyDerivation: KeyDerivation) -> CryptoConfigurationBuilder {
        self.keyDerivation = keyDerivation
        return self
    }
    
    public func setMessageSerialization(_ messageSerialization: MessageSerialization) -> CryptoConfigurationBuilder {
        self.messageSerialization = messageSerialization
        return self
    }
    
    public func build() -> CryptoConfiguration {
        return CryptoConfiguration(keyAgreement: keyAgreement,
                                   symmetricCipher: symmetricCipher,
                                   logging: logging,
                                   keyDerivation: keyDerivation,
                                   messageSerialization: messageSerialization)
    }
}
