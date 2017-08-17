//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class SymmetricCipherGcmTest : XCTestCase{
    let target: SymmetricCipher = TUNAes256GcmCipher()
    
    func testEncrypt() throws {
        //given
        let key = "0f95299026df02b3666d8e33138b1d7a40b5057c381dc0743bdedd96be22f594".hexStringToByteArray()
        let iv = "09d8c8bb745cba35749a839b548b9a7c".hexStringToByteArray()
        let input = "01AA".hexStringToByteArray()
        
        //when
        let result = try target.encrypt(data: input, key: key, iv: iv)
        
        //then
        XCTAssertEqual("5e8b5c582ab685e1ee8454b854137e486b89", result.toHexString())
    }
    
    
    func testDecrypt() throws {
        //given
        let key = "0f95299026df02b3666d8e33138b1d7a40b5057c381dc0743bdedd96be22f594".hexStringToByteArray()
        let iv = "09d8c8bb745cba35749a839b548b9a7c".hexStringToByteArray()
        let encryptedData = "5e8b5c582ab685e1ee8454b854137e486b89".hexStringToByteArray()
        
        //when
        let result = try target.decrypt(data: encryptedData, key: key, iv: iv)
        
        //then
        XCTAssertEqual("01aa", result.toHexString())
    }
    
    
    func testCycle() throws {
        //given
        let key = target.generateKey()
        let iv = target.generateIV()
        
        //when
        let result = try target.encrypt(data: "01AA".hexStringToByteArray(), key: key, iv: iv)
        let decryptionResult = try target.decrypt(data: result, key: key, iv: iv)
        
        //then
        XCTAssertEqual("01aa", decryptionResult.toHexString())
    }
    
    
    func testGenerateKey() {
        //when
        let key = target.generateKey()
        
        //then
        XCTAssertEqual(32, key.count)
    }
    
    
    func testGenerateIV() {
        //when
        let iv = target.generateIV()
        
        //then
        
        XCTAssertEqual(16, iv.count)
    }
}
