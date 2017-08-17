//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class CryptoErrors: NSObject {
        
    public static let domain = "TUNCryptoErrorDomain"
    
    public static let badMacUserInfoKey = "badMacUserInfoKey"
    public static let innerErrorsUserInfoKey = "Errors"
    public static let processedItemsKey = "processedItemsKey"
    
    public static func keyEncryptionError(error: Error) -> String {
        let nsError = error as NSError
        return "KeyEncryptionError - \(nsError.domain)|\(nsError.code)"
    }
    
    public static let untrustedIdentityKeyException = 0

    public static let invalidKeyIdException         = 1
    
    public static let invalidKeyException           = 2
    
    public static let noSessionException            = 3
    
    public static let invalidMessageException       = 4
    
    public static let cipherException               = 5
    
    public static let duplicateMessageException     = 6
    
    public static let legacyMessageException        = 7
    
    public static let invalidVersionException       = 8
    
    public static let messageDeserializationException       = 9
    
    public static let sessioNotInitializedErrorCode = 12
}
