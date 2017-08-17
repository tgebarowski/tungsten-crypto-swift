//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol SessionStore {

    func loadSession(_ contactIdentifier: String, deviceId: String) -> SessionRecord
    //- (NSArray*)subDevicesSessions:(NSString*)contactIdentifier;
    func storeSession(_ contactIdentifier: String, deviceId: String, session: SessionRecord)
    func containsSession(_ contactIdentifier: String, deviceId: String) -> Bool
    func deleteSessionForContact(_ contactIdentifier: String, deviceId: String)
    func deleteAllSessionsForContact(_ contactIdentifier: String, deviceId: String)
}

