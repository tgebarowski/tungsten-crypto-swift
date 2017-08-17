//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class CryptoConfiguration: NSObject {
    public let keyAgreement: KeyAgreement
    public let symmetricCipher: SymmetricCipher
    public let logging: Logging?
    public let keyDerivation: KeyDerivation
    public let messageSerialization: MessageSerialization
    
    init(keyAgreement: KeyAgreement, symmetricCipher: SymmetricCipher, logging: Logging?, keyDerivation: KeyDerivation, messageSerialization: MessageSerialization) {
        self.keyAgreement = keyAgreement
        self.symmetricCipher = symmetricCipher
        self.logging = logging
        self.keyDerivation = keyDerivation
        self.messageSerialization = messageSerialization
    }
}
