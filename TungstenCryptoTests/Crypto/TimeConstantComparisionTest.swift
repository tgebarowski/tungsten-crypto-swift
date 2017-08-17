//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation
import XCTest
@testable import TungstenCrypto

class TimeConstantComparisionTest : XCTestCase {
    
    let dataA = "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray()
    let dataB = "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray()
    
    let dataC = "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray()
    let dataD = "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e37".hexStringToByteArray()
    
    func testEncryptionTimeConstantIsEqual() {
        
        XCTAssertTrue(dataA.timeConstantIsEqual(to: dataA))
        XCTAssertTrue(dataA.timeConstantIsEqual(to: dataB))
        XCTAssertTrue(dataB.timeConstantIsEqual(to: dataA))
        XCTAssertFalse(dataA.timeConstantIsEqual(to: dataC))
        XCTAssertFalse(dataC.timeConstantIsEqual(to: dataA))
        XCTAssertFalse(dataA.timeConstantIsEqual(to: dataD))
        XCTAssertFalse(dataD.timeConstantIsEqual(to: dataA))
        
        XCTAssertTrue(dataB.timeConstantIsEqual(to: dataB))
        XCTAssertFalse(dataB.timeConstantIsEqual(to: dataC))
        XCTAssertFalse(dataC.timeConstantIsEqual(to: dataB))
        XCTAssertFalse(dataB.timeConstantIsEqual(to: dataD))
        XCTAssertFalse(dataD.timeConstantIsEqual(to: dataB))
        
        XCTAssertTrue(dataC.timeConstantIsEqual(to: dataC))
        XCTAssertFalse(dataC.timeConstantIsEqual(to: dataD))
        XCTAssertFalse(dataD.timeConstantIsEqual(to: dataC))
        
        XCTAssertTrue(dataD.timeConstantIsEqual(to: dataD))
    }
}
