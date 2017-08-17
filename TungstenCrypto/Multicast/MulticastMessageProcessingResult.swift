//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class MulticastMessageProcessingResult: NSObject {
    
    private(set) public var decryptedPayload: String
    private(set) public var encryptionInitializationVector: String?
    private(set) public var encryptionKey: String
    private(set) public var consumedInitKeyId: NSNumber?
    
    init(decryptedPayload: String, encryptionInitializationVector: String?, encryptionKey: String, consumedInitKeyId: Int?) {
        self.decryptedPayload = decryptedPayload
        self.encryptionInitializationVector = encryptionInitializationVector
        self.encryptionKey = encryptionKey
        
        if let consumedInitKeyId = consumedInitKeyId {
            self.consumedInitKeyId = NSNumber(integerLiteral: consumedInitKeyId)
        } else {
            self.consumedInitKeyId = nil
        }
    }
    
    public init(decryptedPayload: String, encryptionInitializationVector: String?, encryptionKey: String, consumedInitKeyId: NSNumber?) {
        self.decryptedPayload = decryptedPayload
        self.encryptionInitializationVector = encryptionInitializationVector
        self.encryptionKey = encryptionKey
        self.consumedInitKeyId = consumedInitKeyId
    }
    
}
