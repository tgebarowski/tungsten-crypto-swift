//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>
@protocol MessageSerialization;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
@interface ProtobuffsMessageSerialization : NSObject<MessageSerialization>

@end
#pragma clang diagnostic pop
