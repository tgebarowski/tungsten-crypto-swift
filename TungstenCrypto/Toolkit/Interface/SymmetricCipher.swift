//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

@objc public protocol SymmetricCipher {
    func encrypt(data: Data, key: Data, iv: Data) throws -> Data
    func decrypt(data: Data, key: Data, iv: Data) throws -> Data
    func generateKey() -> Data
    func generateIV() -> Data
}
