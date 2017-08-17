//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>

extern NSString * const TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey;
extern NSString * const TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey;

@interface TUNAes256GcmAuthenticatedCiphertextComposer : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithAuthenticationTagSize:(NSUInteger)authenticationTagSize;

- (NSDictionary *)decomposeAuthenticatedCiphertext:(NSData *)authenticatedCiphertext;

- (NSData *)composeAuthenticatedCiphertextWithCiphertext:(NSData *)ciphertext
                                       authenticationTag:(NSData *)tag;

@end
