//
//  ObjectiveAutocrypt.h
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 07.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface ObjectiveAutocrypt : NSObject
    
- (NSData*) transformKey: (NSString *) string;
    
@end
NS_ASSUME_NONNULL_END

