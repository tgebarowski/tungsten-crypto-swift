//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

public class CryptoToolkit: NSObject {
    
    public static let sharedInstance = CryptoToolkit()
    
    private(set) public var configuration: CryptoConfiguration = CryptoConfigurationBuilder().build()
    private var configurationInitialized = false
    private let initializationQueue = DispatchQueue(label: "CryptoToolkit.initializationQueue")
    
    private override init() {
        
    }
    
    public func setup(_ configuration: CryptoConfiguration) throws {
        try initializationQueue.sync {
            guard configurationInitialized == false else {
                throw ToolkitErrors.toolkitAlreadyInitilizedError()
            }
            self.configuration = configuration
            self.configurationInitialized = true
        }
    }
    
    func cleanup() {
        initializationQueue.sync {
            self.configuration = CryptoConfigurationBuilder().build()
            self.configurationInitialized = false
        }
    }
}
