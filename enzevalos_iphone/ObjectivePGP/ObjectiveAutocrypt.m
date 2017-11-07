//
//  ObjectiveAutocrypt.m
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 07.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

#import "ObjectiveAutocrypt.h"
#import "NSData+PGPUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ObjectiveAutocrypt

- (NSData*) transformKey: (NSString *) string{
    NSMutableDictionary *headers = [@{@"Comment": @"Created with ObjectivePGP",
                                      @"Charset": @"UTF-8"} mutableCopy];
    NSMutableString *headerString = [NSMutableString stringWithString:@"-----"];
    NSMutableString *footerString = [NSMutableString stringWithString:@"-----"];
    [headerString appendString:@"BEGIN PGP PUBLIC KEY BLOCK"];
    [footerString appendString:@"END PGP PUBLIC KEY BLOCK"];
    [headerString appendString:@"-----\n"];
    [footerString appendString:@"-----\n"];
    NSMutableString *armoredMessage = [NSMutableString string];
    // - An Armor Header Line, appropriate for the type of data
    [armoredMessage appendString:headerString];
    
    // - Armor Headers
    for (NSString *key in headers.allKeys) {
        [armoredMessage appendFormat:@"%@: %@\n", key, headers[key]];
    }
    // - A blank (zero-length, or containing only whitespace) line
    [armoredMessage appendString:@"\n"];
    [armoredMessage appendString:string];
    [armoredMessage appendString:@"\n"];
    
    // - An Armor Checksum
    NSData *binaryData = [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UInt32 checksum = [binaryData pgp_CRC24];
    UInt8  c[3]; // 24 bit
    c[0] = checksum >> 16;
    c[1] = checksum >> 8;
    c[2] = checksum;
    NSData *checksumData = [NSData dataWithBytes:&c length:sizeof(c)];
    [armoredMessage appendString:@"="];
    [armoredMessage appendString:[checksumData base64EncodedStringWithOptions:(NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed)]];
    [armoredMessage appendString:@"\n"];
    
    // - The Armor Tail, which depends on the Armor Header Line
    [armoredMessage appendString:footerString];
    
    NSData *armoredData = [armoredMessage dataUsingEncoding:NSASCIIStringEncoding];
    return armoredData;
}

@end
NS_ASSUME_NONNULL_END
