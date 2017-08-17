//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol SignedInitKeyStore {
    func loadSignedInitKey(_ signedInitKeyId: String) -> SignedInitKeyRecord
    func loadSignedInitKeys() -> [SignedInitKeyRecord]
    func storeSignedInitKey(_ signedInitKeyId: String, signedInitKeyRecord: SignedInitKeyRecord)
    func containsSignedInitKey(_ signedInitKeyId: String) -> Bool
    func removeSignedInitKey(_ signedInitKeyId: String)
}
