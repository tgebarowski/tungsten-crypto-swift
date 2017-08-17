//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol KeyDerivation {
    func hmac(seed: Data, key: Data) -> Data
    func hmac(senderIdentityKey: Data, receiverIdentityKey: Data, macKey: Data, serialized: Data) -> Data
    func deriveKey(seed: Data, info: Data, salt: Data) throws -> DerivedSecrets
}
