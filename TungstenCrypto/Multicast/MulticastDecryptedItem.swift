//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class MulticastDecryptedItem: NSObject {
    
    private(set) public var decryptedValue: String
    private(set) public var encryptionInitializationVector: String?
    private(set) public var consumedInitKeyId: NSNumber?
    
    init(decryptedValue: String, encryptionInitializationVector: String?, consumedInitKeyId: Int?) {
        self.decryptedValue = decryptedValue
        self.encryptionInitializationVector = encryptionInitializationVector
        if let consumedInitKeyId = consumedInitKeyId {
            self.consumedInitKeyId = NSNumber(integerLiteral: consumedInitKeyId)
        } else {
            self.consumedInitKeyId = nil
        }
    }
    
    public init(decryptedValue: String, encryptionInitializationVector: String?, consumedInitKeyId: NSNumber?) {
        self.decryptedValue = decryptedValue
        self.encryptionInitializationVector = encryptionInitializationVector
        self.consumedInitKeyId = consumedInitKeyId
    }
}
