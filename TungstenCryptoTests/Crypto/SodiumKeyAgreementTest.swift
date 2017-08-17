//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class SodiumKeyAgreementTest: XCTestCase {
    
    func testChain() {
        
        let target: KeyAgreement = SodiumKeyAgreement()
        let keyPair = target.generateKeyPair()
        
        NSLog("Private key: " + keyPair.privateKey.toHexString())
        NSLog("Public key: " + keyPair.publicKey.toHexString())
        
        let data = "1234".data(using: .utf8)!
        NSLog("data: " + data.toHexString())

        let signature = target.sign(data: data, keyPair: keyPair)
        NSLog("signature: " + signature.toHexString())
        
        let result = target.verify(signature: signature, publicKey: keyPair.publicKey, data: data)

        XCTAssertTrue(result)
    }
    
    func testNilResponseForSharedKey() {
        
        let target: KeyAgreement = SodiumKeyAgreement()
        let keyPair = target.generateKeyPair()
        
        let invalidKey = "asdasdasqweqw".data(using: .utf8)!
        
        let result = target.sharedSecred(from: invalidKey, keyPair: keyPair)
        XCTAssertNil(result)
    }
}


