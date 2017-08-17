//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol KeyAgreement {
    func generateKeyPair() -> KeyPair
    func sharedSecred(from publicKey: Data, keyPair: KeyPair) -> Data?
    
    func sign(data: Data, keyPair: KeyPair) -> Data
    func verify(signature: Data, publicKey: Data, data: Data) -> Bool
}

extension KeyAgreement {
    
    func sharedSecred(from publicKey: Data, keyPair: KeyPair) throws -> Data {
        guard let shared = sharedSecred(from: publicKey, keyPair: keyPair) else {
            throw NSError.errorForSharedSecretGeneration()
        }
        
        return shared
    }
}
