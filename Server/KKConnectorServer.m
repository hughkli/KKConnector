//
//  KKSConnectionManager.m
//  KKServer
//
//  Created by 李凯 on 2020/11/9.
//

#import "KKConnectorServer.h"
#import "PTChannel.h"
#import "KKConnectorDefines.h"
#import "KKConnectorRequest.h"
#import "KKConnectorServerRequestHandler.h"

@interface KKConnectorServer () <PTChannelDelegate>

@property(nonatomic, weak) PTChannel *peerChannel_;

@property(nonatomic, assign) BOOL applicationIsActive;
@property(nonatomic, copy) NSString *sessionID;

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, id<KKConnectorServerDelegate>> *delegatesMap;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *protocolVersionsMap;

@end

@implementation KKConnectorServer

+ (instancetype)sharedInstance {
    static KKConnectorServer *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KKConnectorServer alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.delegatesMap = [NSMutableDictionary dictionary];
        self.protocolVersionsMap = [NSMutableDictionary dictionary];
        self.sessionID = [self genRandomText];
        
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
#elif TARGET_OS_OSX
        [self handleApplicationDidBecomeActive];
#endif
    }
    return self;
}

- (NSString *)genRandomText {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    int number = arc4random() % 10;
    return [NSString stringWithFormat:@"%@%.0f", @(number), timestamp];
}

- (void)handleApplicationDidBecomeActive {
    self.applicationIsActive = YES;
    if (self.peerChannel_ && (self.peerChannel_.isConnected || self.peerChannel_.isListening)) {
        return;
    }
#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
    [self tryToListenOnPortFrom:KKConnectorUSBPortStart to:KKConnectorUSBPortEnd current:KKConnectorUSBPortStart];
#else
    [self tryToListenOnPortFrom:KKConnectorSimPortStart to:KKConnectorSimPortEnd current:KKConnectorSimPortStart];
#endif
}

- (void)handleApplicationWillResignActive {
    self.applicationIsActive = NO;
}

- (void)tryToListenOnPortFrom:(int)fromPort to:(int)toPort current:(int)currentPort  {
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    [channel listenOnPort:currentPort IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (!error) {
            NSLog(@"[KKConnectorServer] Connected successfully on 127.0.0.1:%d", currentPort);
            return;;
        }
        // errorCode 48 表示地址已被占用
        NSLog(@"[KKConnectorServer] 127.0.0.1:%d is unavailable(%@).", currentPort, error);
        if (currentPort < toPort) {
            // 尝试下一个端口
            [self tryToListenOnPortFrom:fromPort to:toPort current:(currentPort + 1)];
        } else {
            // 所有端口都尝试完毕，全部失败
            NSLog(@"[KKConnectorServer] Connection failed.");
        }
    }];
}

- (BOOL)isConnected {
    return self.peerChannel_ && self.peerChannel_.isConnected;
}

- (void)sendData:(NSObject *)data appID:(uint32_t)appID tag:(uint32_t)tag {
    if (!self.peerChannel_) {
        return;
    }
//    NSError *error;
//    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:YES error:&error];
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:data];
//    if (error) {
//        NSLog(@"[KKConnectorServer] Archived data failed: %@", error);
//    }
    
    dispatch_data_t payload = [archivedData createReferencingDispatchData];
    
    [self.peerChannel_ sendFrameOfType:appID tag:tag withPayload:payload callback:^(NSError *error) {
        if (error) {
        }
    }];
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)appID tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    if (channel == self.peerChannel_ && self.delegatesMap[@(appID)] != nil) {
        return YES;
    } else {
        return NO;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)appID tag:(uint32_t)requestTag payload:(PTData*)payload {
    id<KKConnectorServerDelegate> delegate = self.delegatesMap[@(appID)];
    if (delegate == nil) {
        NSLog(@"[KKConnectorServer][E] Did receive frame but no delegate was found. AppID: %@", @(appID));
        return;
    }
    if (!payload) {
        NSLog(@"[KKConnectorServer][E] Did receive frame but no payload. AppID: %@", @(appID));
        return;
    }
    id unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfDispatchData:payload.dispatchData]];
    if (![unarchived isKindOfClass:[KKConnectorRequest class]]) {
        NSLog(@"[KKConnectorServer][E] Did receive frame but payload was not KKConnectorRequest but %@.", unarchived);
        return;
    }
    KKConnectorRequest *request = (KKConnectorRequest *)unarchived;
    NSLog(@"[KKConnectorServer] Did receive request with header: %@", request.header);
    
    if (requestTag == 0) {
        // push 消息，不需要回复
        [delegate connectorServerDidReceiveRequestHeader:request.header body:request.body handler:nil];
        return;
    }
    
    KKConnectorServerRequestHandler *handler = [[KKConnectorServerRequestHandler alloc] initWithAppID:appID requestTag:requestTag];
    if (!self.applicationIsActive) {
        [handler errorWithCode:KKConnectorError_BackgroundState description:@"Server application has resigned active."];
        return;
    }

    if ([request.header isEqualToString:KKConnectorHeaderPing]) {
        NSString *serverProtocolVersion = self.protocolVersionsMap[@(appID)];
        NSDictionary *param = @{
            @"version": serverProtocolVersion,
            @"session": self.sessionID
        };
        [handler just:param];
    } else {
        [delegate connectorServerDidReceiveRequestHeader:request.header body:request.body handler:handler];
    }
}

/// 当连接过 Lookin 客户端，然后 Lookin 客户端又被关闭时，会走到这里
- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
}

- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address {
    if (self.peerChannel_) {
        [self.peerChannel_ cancel];
    }
    
    self.peerChannel_ = otherChannel;
    self.peerChannel_.userInfo = address;
}

#pragma mark - Public

- (void)registerAppID:(unsigned int)appID protocolVersion:(NSString *)protocolVersion delegate:(id<KKConnectorServerDelegate>)delegate {
    self.delegatesMap[@(appID)] = delegate;
    self.protocolVersionsMap[@(appID)] = protocolVersion;

    NSLog(@"[KKConnectorServer] Registered with appID: %@, protocolVersion: %@, delegate: %@", @(appID), protocolVersion, delegate);
}

- (void)pushWithAppID:(unsigned int)appID header:(NSString *)header body:(id)body {
    KKConnectorRequest *request = [KKConnectorRequest new];
    request.header = header;
    request.body = body;
    [self sendData:request appID:appID tag:KKConnectorTagForPush];
}

@end
