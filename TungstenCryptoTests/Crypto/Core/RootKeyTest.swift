//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class RootKeyTest: XCTestCase {

    func testShouldCreateRkckChain() throws {
        //given
        let pk1 = "973909a0fcb3c65af34671560e2c22a70e92ba918a79f737d1e8e76eaf2013ad".hexStringToByteArray()
        let privateKey = ("cf4913cf910a3df1254f81747cd718ee7d8b21bbfa60fef0f8c9b3d74d333efa0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a").hexStringToByteArray()
        let publicKey = "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray()
        let keyPair = KeyPair(privateKey: privateKey, publicKey: publicKey)
        let target = RootKey(data: publicKey)
        
        //when
        let result = try target.createChain(theirEphemeral: pk1, ourEphemeral: keyPair)
        
        //then
        XCTAssertEqual("759f82dda9ae4824018414c93d2a6c23ab0bf736c65e816665c934e485505074",
                       result.chainKey.key.toHexString())
        XCTAssertEqual(0, result.chainKey.index)
        XCTAssertEqual("7fa706759fa77ac4840b2f228fc6979899cd912eb8081d59428575c808997845",
                       result.rootKey.keyData.toHexString())
    }
}
