//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import TungstenCrypto

class MockedIdentityKeyStore : IdentityKeyStore{
    
    public var identity: KeyPair? = nil
    
    var keys = [String : Data]()
    
    func identityKeyPair() -> KeyPair {
        return identity!
    }
    
    func localRegistrationId() -> String {
        return "1001"
    }
    
    func saveRemoteIdentity(_ identityKey: Data, recipientId: String, deviceId: String) {
        keys[combineKey(recipientId, deviceId)] = identityKey
    }
    
    func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, deviceId: String) -> Bool {
        if(keys[combineKey(recipientId, deviceId)] == nil){
            return true
        }
        
        return keys[combineKey(recipientId, deviceId)]?.toHexString() == identityKey.toHexString()
    }
}
