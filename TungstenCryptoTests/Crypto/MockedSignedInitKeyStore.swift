//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import TungstenCrypto

class MockedSignedInitKeyStore : SignedInitKeyStore{
    
    var sessions = [String: SignedInitKeyRecord]()
    
    func loadSignedInitKey(_ signedInitKeyId: String) -> SignedInitKeyRecord {
        return sessions[signedInitKeyId]!
    }
    
    func loadSignedInitKeys() -> [SignedInitKeyRecord]{
        return Array(sessions.values)
    }
    
    func storeSignedInitKey(_ signedInitKeyId: String, signedInitKeyRecord: SignedInitKeyRecord) {
        sessions[signedInitKeyId] = signedInitKeyRecord
    }
    
    func containsSignedInitKey(_ signedInitKeyId: String) -> Bool {
        return false
    }
    
    func removeSignedInitKey(_ signedInitKeyId: String) {
        sessions.removeValue(forKey: signedInitKeyId)
    }
}
