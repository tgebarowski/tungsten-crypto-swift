//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class InitKeySecretMessageContainer: NSObject {
    
    public var signedInitKeyId: String?
    public var baseKey: Data?
    public var identityKey: Data?
    public var message: Data?
    public var registrationId: String?
    public var initKeyId: NSNumber?
    
    public init(signedInitKeyId: String?, baseKey: Data?, identityKey: Data?, message: Data?, registrationId: String?, initKeyId: NSNumber?) {
        self.signedInitKeyId = signedInitKeyId
        self.baseKey = baseKey
        self.identityKey = identityKey
        self.message = message
        self.registrationId = registrationId
        self.initKeyId = initKeyId
    }
}
