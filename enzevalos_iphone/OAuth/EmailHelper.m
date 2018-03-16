//
//  EmailHelper.m
//  enzevalos_iphone
//
//  Created by Joscha on 29.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

#import "EmailHelper.h"
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>

/*! @brief The OIDC issuer from which the configuration will be discovered.
 */
static NSString *const kIssuer = @"https://accounts.google.com";

/*! @brief The OAuth client ID.
 @discussion For Google, register your client at
 https://console.developers.google.com/apis/credentials?project=_
 The client should be registered with the "iOS" type.
 */
static NSString *const kClientID = @"459157836079-csn0a9p3r8p7q6216fn5u7a6vcum80gn.apps.googleusercontent.com";

/*! @brief The OAuth redirect URI for the client @c kClientID.
 @discussion With Google, the scheme of the redirect URI is the reverse DNS notation of the
 client ID. This scheme must be registered as a scheme in the project's Info
 property list ("CFBundleURLTypes" plist key). Any path component will work, we use
 'oauthredirect' here to help disambiguate from any other use of this scheme.
 */
static NSString *const kRedirectURI =
@"com.googleusercontent.apps.459157836079-csn0a9p3r8p7q6216fn5u7a6vcum80gn:/oauthredirect";

/*! @brief @c NSCoding key for the authState property. You don't need to change this value.
 */
static NSString *const kExampleAuthorizerKey = @"googleOAuthCodingKey";

@interface EmailHelper ()   <OIDAuthStateChangeDelegate,
                            OIDAuthStateErrorDelegate>
@end

@implementation EmailHelper

static dispatch_once_t pred;
static EmailHelper *shared = nil;

+ (EmailHelper *)singleton {
    dispatch_once(&pred, ^{ shared = [[EmailHelper alloc] init]; });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        [self loadState];
    }
    return self;
}

#pragma mark -

// CALL THIS TO START
- (void)doEmailLoginIfRequiredOnVC:(UIViewController*)vc completionBlock:(dispatch_block_t)completionBlock {
    dispatch_async(dispatch_get_main_queue(), ^{

        // first see if we already have authorization
        [self checkIfAuthorizationIsValid:^(BOOL authorized) {
            NSAssert([NSThread currentThread].isMainThread, @"ERROR MAIN THREAD NEEDED");
            if (authorized) {
                if (completionBlock)
                completionBlock();
            } else {
                [self doInitialAuthorizationWithVC:vc completionBlock:completionBlock];
            }
        }];
    });
}

/*! @brief Saves the @c GTMAppAuthFetcherAuthorization to @c NSUSerDefaults.
 */
- (void)saveState {
    if (_authorization.canAuthorize) {
        [GTMAppAuthFetcherAuthorization saveAuthorization:_authorization toKeychainForName:kExampleAuthorizerKey];
    } else {
        NSLog(@"EmailHelper: WARNING, attempt to save a google authorization which cannot authorize, discarding");
        [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kExampleAuthorizerKey];
    }
}

/*! @brief Loads the @c GTMAppAuthFetcherAuthorization from @c NSUSerDefaults.
 */
- (void)loadState {
    GTMAppAuthFetcherAuthorization* authorization =
    [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kExampleAuthorizerKey];
    
    if (authorization.canAuthorize) {
        self.authorization = authorization;
        self.authorization.authState.stateChangeDelegate = self;
        self.authorization.authState.errorDelegate = self;
    } else {
        NSLog(@"EmailHelper: WARNING, loaded google authorization cannot authorize, discarding");
        [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kExampleAuthorizerKey];
    }
    
    
}

- (void)doInitialAuthorizationWithVC:(UIViewController*)vc completionBlock:(dispatch_block_t)completionBlock {
    NSURL *issuer = [NSURL URLWithString:kIssuer];
    NSURL *redirectURI = [NSURL URLWithString:kRedirectURI];
    
    NSLog(@"EmailHelper: Fetching configuration for issuer: %@", issuer);
    
    // discovers endpoints
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {
        if (!configuration) {
            NSLog(@"EmailHelper: Error retrieving discovery document: %@", [error localizedDescription]);
            self.authorization = nil;
            return;
        }
        
        NSLog(@"EmailHelper: Got configuration: %@", configuration);
        
        // builds authentication request
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                        scopes:@[OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail, @"https://mail.google.com/"]
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
        // performs authentication request
        NSLog(@"EmailHelper: Initiating authorization request with scope: %@", request.scope);
        self.currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request presentingViewController:vc callback:^(OIDAuthState *_Nullable authState, NSError *_Nullable error) {
            if (authState) {
                self.authorization = [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
                NSLog(@"EmailHelper: Got authorization tokens. Access token: %@", authState.lastTokenResponse.accessToken);
                [self saveState];
            } else {
                self.authorization = nil;
                NSLog(@"EmailHelper: Authorization error: %@", [error localizedDescription]);
            }
            if (completionBlock)
            dispatch_async(dispatch_get_main_queue(), completionBlock);
        }];
    }];
}

// Performs a UserInfo request to the account to see if the token works
- (void)checkIfAuthorizationIsValid:(void (^)(BOOL authorized))completionBlock {
    NSLog(@"EmailHelper: Performing userinfo request");
    
    // Creates a GTMSessionFetcherService with the authorization.
    // Normally you would save this service object and re-use it for all REST API calls.
    GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
    fetcherService.authorizer = self.authorization;
    
    // Creates a fetcher for the API call.
    NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/userinfo"];
    GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        // Checks for an error.
        if (error) {
            // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
            if ([error.domain isEqual:OIDOAuthTokenErrorDomain]) {
                [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kExampleAuthorizerKey];
                self.authorization = nil;
                NSLog(@"EmailHelper: Authorization error during token refresh, cleared state. %@", error);
                if (completionBlock)
                completionBlock(NO);
            } else {
                // Other errors are assumed transient.
                NSLog(@"EmailHelper: Transient error during token refresh. %@", error);
                if (completionBlock)
                completionBlock(NO);
            }
            return;
        }
        
        NSLog(@"EmailHelper: authorization is valid");
        if (completionBlock)
        completionBlock(YES);
    }];
}

- (void)didChangeState:(nonnull OIDAuthState *)state {
    [self saveState];
}

- (void)authState:(nonnull OIDAuthState *)state didEncounterAuthorizationError:(nonnull NSError *)error {
    NSLog(@"Received authorization error: %@", error);
}

@end
