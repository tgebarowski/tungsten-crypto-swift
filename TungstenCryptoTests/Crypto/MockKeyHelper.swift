//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

func combineKey(_ contactIdentifier: String, _ deviceId: String) -> String {
    return contactIdentifier + String(deviceId)
}
