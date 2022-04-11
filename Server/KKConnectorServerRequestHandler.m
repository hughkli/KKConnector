//
//  KKConnectorServerRequestHandler.m
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import "KKConnectorServerRequestHandler.h"
#import "KKConnectorServer.h"
#import "KKConnectorResponse.h"

@interface KKConnectorServer (Private_RequestHandler)

- (void)sendData:(NSObject *)data appID:(uint32_t)appID tag:(uint32_t)tag;

@end

@interface KKConnectorServerRequestHandler ()

@property(nonatomic, assign) int totalSize;
@property(nonatomic, assign) uint32_t appID;
@property(nonatomic, assign) uint32_t requestTag;

@end

@implementation KKConnectorServerRequestHandler

- (instancetype)initWithAppID:(uint32_t)appID requestTag:(uint32_t)tag {
    if (self = [super init]) {
        self.appID = appID;
        self.requestTag = tag;
        self.totalSize = 1;
    }
    return self;
}

- (void)errorWithCode:(int)errorCode description:(NSString *)errorDescription {
    NSLog(@"[KKConnectorServer] Respond with error code: %@, desc: %@", @(errorCode), errorDescription);
    
    KKConnectorResponse *response = [KKConnectorResponse new];
    response.totalSize = self.totalSize;
    response.thisSize = 1;
    response.hasError = YES;
    response.errorCode = errorCode;
    response.errorDescription = errorDescription;
    [[KKConnectorServer sharedInstance] sendData:response appID:self.appID tag:self.requestTag];
}

- (void)just:(NSObject<NSSecureCoding> * _Nullable)data {
    NSLog(@"[KKConnectorServer] Respond with single data.");
    
    KKConnectorResponse *response = [KKConnectorResponse new];
    response.totalSize = self.totalSize;
    response.thisSize = 1;
    response.body = data;
    [[KKConnectorServer sharedInstance] sendData:response appID:self.appID tag:self.requestTag];
}

- (void)startWithTotalSize:(int)size {
    self.totalSize = size;
}

- (void)respond:(NSObject<NSCoding> *)data thisSize:(int)size {
    NSLog(@"[KKConnectorServer] Respond with size: %@, total size: %@", @(size), @(self.totalSize));
    
    KKConnectorResponse *response = [KKConnectorResponse new];
    response.totalSize = self.totalSize;
    response.thisSize = size;
    response.body = data;

    if (response.totalSize <= 0) {
        NSAssert(NO, @"必须先调用 startWithTotalSize");
        response.totalSize = 1;
    }
    
    [[KKConnectorServer sharedInstance] sendData:response appID:self.appID tag:self.requestTag];
}

@end
