//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface NSMutableString (DebugDescription)

- (void)addLine:(NSString *)line indentationLevel:(NSInteger)indentation;

@end

@interface SessionState (DebugDescription)

- (NSString *)debugDescriptionWithIndentation:(NSInteger)indentation;

@end

@interface MessageKeys (DebugDescription)

- (NSString *)debugDescriptionWithIndentation:(NSInteger)indentation;

@end
