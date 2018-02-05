//
//  AuthStateDelegate.m
//  enzevalos_iphone
//
//  Created by joscha1 on 05.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppAuth/AppAuth.h>
#import "AuthStateDelegate.h"

@implementation AuthStateDelegate

- (id)init
{
    return [super init];
}

- (void)didChangeState:(OIDAuthState *)state
{
    printf("%s", state.description);
}

- (void)authState:(OIDAuthState *)state didEncounterAuthorizationError:(NSError *)error
{
    printf("%s", error.description);
}

- (void)authState:(OIDAuthState *)state didEncounterTransientError:(NSError *)error
{
    printf("%s", error.description);
}

@end
