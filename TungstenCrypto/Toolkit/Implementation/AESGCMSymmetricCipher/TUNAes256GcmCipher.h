//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>

@protocol SymmetricCipher;

extern NSUInteger const TUNAes256AuthenticationTagSize;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
@interface TUNAes256GcmCipher : NSObject <SymmetricCipher>

@end

#pragma clang diagnostic pop
