//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import TungstenCrypto

class MockedSessionStore : SessionStore{
    
    var sessions = [String : Data]()
    
    func loadSession(_ contactIdentifier: String, deviceId: String) -> SessionRecord{
        let sessionToReturn: SessionRecord
        if(!containsSession(contactIdentifier, deviceId: deviceId)){
            sessionToReturn = SessionRecord()
        } else {
            sessionToReturn = NSKeyedUnarchiver.unarchiveObject(with:  sessions[combineKey(contactIdentifier, deviceId)]!) as! SessionRecord
        }
        return sessionToReturn
    }
    
    func storeSession(_ contactIdentifier: String, deviceId: String, session: SessionRecord){
        sessions[combineKey(contactIdentifier, deviceId)] = NSKeyedArchiver.archivedData(withRootObject: session)
    }
    
    func containsSession(_ contactIdentifier: String, deviceId: String) -> Bool {
        return sessions[combineKey(contactIdentifier, deviceId)] != nil
    }
    
    func deleteSessionForContact(_ contactIdentifier: String, deviceId: String){
        sessions.removeValue(forKey: combineKey(contactIdentifier, deviceId))
    }
    
    func deleteAllSessionsForContact(_ contactIdentifier: String, deviceId: String){
        sessions.removeValue(forKey: combineKey(contactIdentifier, deviceId))
    }
}
