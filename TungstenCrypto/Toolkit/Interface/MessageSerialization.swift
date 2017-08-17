//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol MessageSerialization {
    func encodeMessage(message: SecretMessage) -> Data
    func decodeMessage(data: Data) throws -> SecretMessageContainer
    
    func encodeInitKeyMessage(initKeyMessage: InitKeySecretMessage) -> Data
    func decodeInitKeyMessage(data: Data) throws -> InitKeySecretMessageContainer
}
