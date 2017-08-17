//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class EncryptionResults: NSObject {
    
    public let succeed: [String: MulticastEncryptedItem]
    public let failed: [String: Error]
    
    public init(succeed: [String: MulticastEncryptedItem], failed: [String: Error]) {
        self.succeed = succeed
        self.failed = failed
    }
}
