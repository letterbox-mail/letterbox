//
//  EmailHelper.h
//  enzevalos_iphone
//
//  Created by Joscha on 29.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>

@interface EmailHelper : NSObject

+ (EmailHelper *)singleton;

@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentAuthorizationFlow;
@property(nonatomic, nullable) GTMAppAuthFetcherAuthorization *authorization;

- (void)doEmailLoginIfRequiredOnVC:(UIViewController*)vc completionBlock:(dispatch_block_t)completionBlock;

@end
