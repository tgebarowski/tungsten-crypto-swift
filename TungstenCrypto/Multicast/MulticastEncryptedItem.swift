//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class MulticastEncryptedItem: NSObject {
    
    private(set) public var encryptedValue: String
    private(set) public var deviceMulticastId: String
    
    public init(encryptedValue: String, deviceMulticastId: String) {
        self.encryptedValue = encryptedValue
        self.deviceMulticastId = deviceMulticastId
    }
}
