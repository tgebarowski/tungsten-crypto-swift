//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation


class RemoteAddress{
    
    var recipientId: String
    var deviceId: String
    
    init(_ recipientId: String, _ deviceId: String) {
        self.recipientId = recipientId
        self.deviceId = deviceId
    }
}
