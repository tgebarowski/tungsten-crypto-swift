//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol InitKeyStore {
    func loadInitKey(_ initKeyId: Int) -> InitKeyRecord?
    func storeInitKey(_ initKeyId: Int, initKeyRecord: InitKeyRecord)
    func containsInitKey(_ initKeyId: Int) -> Bool
    func removeInitKey(_ initKeyId: Int)
}
