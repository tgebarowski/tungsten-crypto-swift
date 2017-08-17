//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class MultiCastMessageHeader: NSObject {
    private(set) public var senderId: String
    private(set) public var senderDeviceId: String
    private(set) public var initializationVector: String
    private(set) public var keys: [MulticastEncryptedItem]
    
    public init(senderId: String, senderDeviceId: String, initializationVector: String, keys: [MulticastEncryptedItem]) {
        self.senderId = senderId
        self.senderDeviceId = senderDeviceId
        self.initializationVector = initializationVector
        self.keys = keys
    }
    
    convenience public init(senderId: String, senderDeviceId: String, initializationVector: String, keysArray: [[String: Any]]) {
        var keys: [MulticastEncryptedItem] = []
        
        for dictionary in keysArray {
            guard let multicastId = dictionary["device_multicast_id"] as? String,
                let encryptedValue = dictionary["encrypted_value"] as? String else {
                    continue
            }
            
            keys.append(MulticastEncryptedItem(encryptedValue: encryptedValue, deviceMulticastId: multicastId))
        }
        
        self.init(senderId: senderId, senderDeviceId: senderDeviceId, initializationVector: initializationVector, keys: keys)
        
    }

    public func arrayOfKeys() -> [[String: Any]] {
        return self.keys.map { ["device_multicast_id" : $0.deviceMulticastId,
                                "encrypted_value" : $0.encryptedValue] }
    }
}

extension MultiCastMessageHeader: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        return MultiCastMessageHeader(senderId: self.senderId, senderDeviceId: self.senderDeviceId, initializationVector: self.initializationVector, keys: keys.map { $0.copy() as! MulticastEncryptedItem })
    }
}

extension MulticastEncryptedItem: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        return MulticastEncryptedItem(encryptedValue: self.encryptedValue, deviceMulticastId: self.deviceMulticastId)
    }
}
