//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class ToolkitErrors: NSObject {
    
    public static let domain = "TUNToolkitErrorsDomain"
    
    public static let toolkitAlreadyInitilizedErrorCode = 0
    
    public static func toolkitAlreadyInitilizedError() -> Error {
        return NSError(domain: domain, code: toolkitAlreadyInitilizedErrorCode, userInfo: nil)
    }
}
