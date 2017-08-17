//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

@objc public protocol CipherMessage {
    var serialized: Data { get }
    init(data: Data) throws
    func verifyMac(senderIdentityKey: Data, receiverIdentityKey: Data, macKey: Data) throws
}
