//
//  Copyright (c) Marcin Krzyżanowski. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY
//  INTERNATIONAL COPYRIGHT LAW. USAGE IS BOUND TO THE LICENSE AGREEMENT.
//  This notice may not be removed from this file.
//

#import "PGPUserAttributeSubpacket.h"
#import "PGPPacket.h"

NS_ASSUME_NONNULL_BEGIN

@interface PGPUserAttributePacket : PGPPacket <NSCopying>

@property (nonatomic, copy) NSArray<PGPUserAttributeSubpacket *> *subpackets;

@end

NS_ASSUME_NONNULL_END
