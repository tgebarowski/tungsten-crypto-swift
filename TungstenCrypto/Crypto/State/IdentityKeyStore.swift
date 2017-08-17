//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol IdentityKeyStore {
    func identityKeyPair() -> KeyPair
    func localRegistrationId() -> String
    func saveRemoteIdentity(_ identityKey: Data, recipientId: String, deviceId: String)
    func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, deviceId: String) -> Bool
}
