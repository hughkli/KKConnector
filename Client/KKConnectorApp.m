//
//  KKConnectorApp.m
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/10.
//

#import "KKConnectorApp.h"
#import "KKConnectorClient.h"
#import "PTChannel.h"
#import "KKConnectorError.h"

@interface KKConnectorClient (KKConnectorApp)

NS_ASSUME_NONNULL_BEGIN

- (void)requestWithChannel:(PTChannel *)channel header:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body timeoutInterval:(NSTimeInterval)timeoutInterval succ:(void (^)(NSObject * _Nullable data))succBlock fail:(void (^)(NSError *error))failBlock completion:(void (^)(void))completionBlock;

- (void)cancelRequestInChannel:(PTChannel *)channel header:(NSString *)header;

- (void)pushInChannel:(PTChannel *)channel header:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body;

- (BOOL)isServerVersionValid:(NSString *)serverVersion;

NS_ASSUME_NONNULL_END

@end

@interface KKConnectorApp ()

@property(nonatomic, strong) PTChannel *channel;

@end

@implementation KKConnectorApp

- (instancetype)initWithChannel:(PTChannel *)channel serverProtocolVersion:(NSString *)serverProtocolVersion sessionID:(NSString *)sessionID {
    if (self = [super init]) {
        self.channel = channel;
        _serverProtocolVersion = serverProtocolVersion;
        _sessionID = sessionID;
    }
    return self;
}

- (void)requestWithHeader:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body succBlock:(void (^)(NSObject * _Nullable result))succBlock completionBlock:(void (^)(void))completionBlock errorBlock:(void (^)(NSError * error))errorBlock {
    if (![self isServerVersionValid]) {
        NSAssert(NO, @"");
        if (errorBlock) {
            errorBlock([KKConnectorError protocolVersionNotMatched]);
        }
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    [[KKConnectorClient sharedInstance] requestWithChannel:self.channel header:header body:body timeoutInterval:3 succ:^(NSObject * _Nullable data) {
        succBlock(data);
    } fail:^(NSError * _Nonnull error) {
        errorBlock(error);
    } completion:^{
        completionBlock();
    }];
}

- (void)pushWithHeader:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body {
    [[KKConnectorClient sharedInstance] pushInChannel:self.channel header:header body:body];
}

- (void)cancelRequestWithHeader:(NSString *)header {
    [[KKConnectorClient sharedInstance] cancelRequestInChannel:self.channel header:header];
}

- (BOOL)isConnected {
    BOOL result = self.channel.isConnected;
    return result;
}

- (BOOL)isServerVersionValid {
    return [KKConnectorClient.sharedInstance isServerVersionValid:self.serverProtocolVersion];
}

@end
