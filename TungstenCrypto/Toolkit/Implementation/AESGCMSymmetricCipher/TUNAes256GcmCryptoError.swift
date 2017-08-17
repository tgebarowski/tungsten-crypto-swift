//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class TUNAes256GcmCryptoErrors: NSObject {
    public static let domain = "TUNAes256GcmCryptoErrorDomain"
    
    public static let  unableToEncryptErrorCode = 1
    public static let  unableToDecryptErrorCode = 2
    public static let  tagNotProvidedErrorCode = 3
    public static let  iVExceedsMaxLengthErrorCode = 4
    public static let  keyExceedsMaxLengthErrorCode = 5
    public static let  verificationFailedErrorCode = 6
}
