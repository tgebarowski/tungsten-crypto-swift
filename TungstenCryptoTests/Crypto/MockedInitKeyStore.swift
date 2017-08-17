//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import TungstenCrypto

class MockedInitKeyStore : InitKeyStore{
    
    var keys = [Int : InitKeyRecord]()
    
    func loadInitKey(_ initKeyId: Int) -> InitKeyRecord?{
        return keys[initKeyId]
    }
    
    func storeInitKey(_ initKeyId: Int, initKeyRecord: InitKeyRecord){
        keys[initKeyId] = initKeyRecord
    }
    
    func containsInitKey(_ initKeyId: Int) -> Bool {
        return keys[initKeyId] != nil
    }
    
    func removeInitKey(_ initKeyId: Int){
        keys.removeValue(forKey: initKeyId)
    }
}
