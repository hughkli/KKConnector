//
//  KKConnectorClient.m
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/10.
//

#import "KKConnectorClient.h"
#import "PTChannel.h"
#import "KKConnectorPort.h"
#import "KKConnectorDefines.h"
#import "KKConnectorRequestKeeper.h"
#import "PTChannel+KKConnector.h"
#import "KKConnectorResponse.h"
#import "KKConnectorError.h"
#import "KKConnectorRequest.h"
#import "KKConnectorApp.h"

@interface KKConnectorClient () <PTChannelDelegate>

@property(nonatomic, assign) uint32_t appID;
@property(nonatomic, strong) id<KKConnectorClientDelegate> delegate;

@property(nonatomic, copy) NSArray<KKConnectorSimulatorPort *> *allSimulatorPorts;
@property(nonatomic, strong) NSMutableArray<KKConnectorUSBPort *> *allUSBPorts;

@property(nonatomic, strong) NSMutableArray<KKConnectorApp *> *foundApps;

@end

@implementation KKConnectorClient

+ (instancetype)sharedInstance {
    static KKConnectorClient *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KKConnectorClient alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.allSimulatorPorts = ({
            NSMutableArray<KKConnectorSimulatorPort *> *ports = [NSMutableArray array];
            for (int number = KKConnectorSimPortStart; number <= KKConnectorSimPortEnd; number++) {
                KKConnectorSimulatorPort *port = [KKConnectorSimulatorPort new];
                port.portNumber = number;
                [ports addObject:port];
            }
            ports;
        });
        self.allUSBPorts = [NSMutableArray array];
        
        [self startUSBListening];
    }
    return self;
}

- (void)startUSBListening {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
        
        /// 仅一台真机 device 上的所有 app 共享同一批端口（在 Lookin 里是 47175 ~ 47179 这 5 个），不同真机互不影响。比如依次启动“真机 A 的 app1”、“真机 A 的 app2”、“真机 B 的 app3”，则它们依次会占用 47175、47176、47175（注意不是 47177）这几个端口
        for (int number = KKConnectorUSBPortStart; number <= KKConnectorUSBPortEnd; number++) {
            KKConnectorUSBPort *port = [KKConnectorUSBPort new];
            port.portNumber = number;
            port.deviceID = deviceID;
            [self.allUSBPorts addObject:port];
        }
        NSLog(@"KKConnector - USB 设备插入，DeviceID: %@", deviceID);
    }];
    
    [nc addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
        [self.allUSBPorts.copy enumerateObjectsUsingBlock:^(KKConnectorUSBPort * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([port.deviceID isEqual:deviceID]) {
                [self.allUSBPorts removeObject:port];
            }
        }];
        NSLog(@"KKConnector - USB 设备拔出，DeviceID: %@", deviceID);
    }];
}

- (void)searchApps:(void (^)(NSArray<KKConnectorApp *> *))completion {
    [self searchConnectedChannels:^(NSArray<PTChannel *> *channels) {
        NSUInteger callbackTotalCount = channels.count;
        if (callbackTotalCount == 0) {
            self.foundApps = @[];
            completion(@[]);
            return;
        }
        
        __block NSUInteger callbackCount = 0;
        NSMutableArray<KKConnectorApp *> *resultApps = [NSMutableArray array];
        
        for (PTChannel *channel in channels) {
            [self pingChannel:channel timeout:1 completion:^(PTChannel *connectedChannel, NSString *serverProtocolVersion, NSString *sessionID, NSError *error) {
                if (error == nil) {
                    KKConnectorApp *app = [[KKConnectorApp alloc] initWithChannel:connectedChannel serverProtocolVersion:serverProtocolVersion sessionID:sessionID];
                    [resultApps addObject:app];
                }
                callbackCount++;
                if (callbackCount >= callbackTotalCount) {
                    [resultApps sortUsingComparator:^NSComparisonResult(KKConnectorApp * _Nonnull obj1, KKConnectorApp * _Nonnull obj2) {
                        return [obj1.sessionID compare:obj2.sessionID];
                    }];
                    self.foundApps = resultApps;
                    completion(resultApps);
                }
            }];
        }
    }];
}

- (void)pingChannel:(PTChannel *)channel timeout:(NSTimeInterval)timeoutInterval completion:(void (^)(PTChannel *channel, NSString *serverProtocolVersion, NSString *sessionID, NSError *error))completion {
    [self requestWithChannel:channel header:KKConnectorHeaderPing body:nil timeoutInterval:timeoutInterval succ:^(NSObject *data) {
        if (![data isKindOfClass:[NSDictionary class]]) {
            completion(nil, nil, nil, [KKConnectorError inner]);
            return;
        }
        NSDictionary *dict = data;
        NSString *protocolVersion = dict[@"version"];
        NSString *sessionID = dict[@"session"];
        completion(channel, protocolVersion, sessionID, nil);
    } fail:^(NSError *error) {
        completion(nil, nil, nil, error);
    } completion:nil];
}

/// 尝试连接所有可能的 Simulator 和 USB 端口，data 为 NSArray<PTChannel>，即所有成功连接的 PTChannel（虽然成功连接但是 app 可能在后台之类的无法执行代码）
- (void)searchConnectedChannels:(void (^)(NSArray<PTChannel *> *))completion {
    __block int callbackCount = 0;
    __block int callbackTotalCount = 2;
    NSMutableArray<PTChannel *> *resultChannels = [NSMutableArray array];
    [self tryToConnectAllUSBDevices:^(NSArray<PTChannel *> *channels) {
        [resultChannels addObjectsFromArray:channels];
        
        callbackCount++;
        if (callbackCount >= callbackTotalCount) {
            completion(resultChannels);
        }
    }];
    [self tryToConnectAllSimulatorPorts:^(NSArray<PTChannel *> *channels) {
        [resultChannels addObjectsFromArray:channels];
        
        callbackCount++;
        if (callbackCount >= callbackTotalCount) {
            completion(resultChannels);
        }
    }];
}

/// 返回所有已成功连接的 PTChannel 数组
- (void)tryToConnectAllSimulatorPorts:(void (^)(NSArray<PTChannel *> *))completion {
    NSMutableArray<PTChannel *> *resultChannels = [NSMutableArray array];
    __block NSUInteger callbackCount = 0;
    __block NSUInteger callbackTotalCount = self.allSimulatorPorts.count;
    
    [self.allSimulatorPorts enumerateObjectsUsingBlock:^(KKConnectorSimulatorPort * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
        [self connectToSimulatorPort:port completion:^(PTChannel *channel, NSError *error) {
            if (channel) {
                [resultChannels addObject:channel];
            }
            callbackCount++;
            if (callbackCount >= callbackTotalCount) {
                completion(resultChannels);
            }
        }];
    }];
}

/// 返回的 x 为成功链接的 PTChannel
/// 注意，如果某个 app 被退到了后台但是没有被 kill，则在这个方法里它的 channel 仍然会被成功连接
- (void)connectToSimulatorPort:(KKConnectorSimulatorPort *)port completion:(void (^)(PTChannel *, NSError *))completion {
    if (port.connectedChannel) {
        // 该 port 本来就已经成功连接
        completion(port.connectedChannel, nil);
        return;
    }
    
    PTChannel *localChannel = [PTChannel channelWithDelegate:self];
    [localChannel connectToPort:port.portNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error, PTAddress *address) {
        if (error) {
            if (error.domain == NSPOSIXErrorDomain && (error.code == ECONNREFUSED || error.code == ETIMEDOUT)) {
                // 没有 iOS 客户端
            } else {
                // 意外
            }
            [localChannel close];
            completion(nil, error);
        } else {
            port.connectedChannel = localChannel;
            completion(localChannel, nil);
        }
    }];
}

/// callback 是所有已成功连接的 PTChannel 数组
- (void)tryToConnectAllUSBDevices:(void (^)(NSArray<PTChannel *> *))completion {
    if (!self.allUSBPorts.count) {
        completion(@[]);
        return;
    }
    
    __block NSUInteger callbackCount = 0;
    __block NSUInteger callbackTotalCount = self.allUSBPorts.count;
    NSMutableArray<PTChannel *> *resultChannels = [NSMutableArray array];
    [self.allUSBPorts enumerateObjectsUsingBlock:^(KKConnectorUSBPort * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
        [self connectToUSBPort:port completion:^(PTChannel *channel, NSError *error) {
            if (channel) {
                [resultChannels addObject:channel];
            }
            callbackCount++;
            if (callbackCount >= callbackTotalCount) {
                completion(resultChannels);
            }
        }];
    }];
}

/// 返回的 x 为成功链接的 PTChannel
- (void)connectToUSBPort:(KKConnectorUSBPort *)port completion:(void (^)(PTChannel *, NSError *))completion {
    if (port.connectedChannel) {
        // 该 port 本来就已经成功连接
        completion(port.connectedChannel, nil);
        return;
    }
    
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    [channel connectToPort:port.portNumber overUSBHub:PTUSBHub.sharedHub deviceID:port.deviceID callback:^(NSError *error) {
        if (error) {
            if (error.domain == PTUSBHubErrorDomain && error.code == PTUSBHubErrorConnectionRefused) {
                // error
            } else {
                // error
            }
            [channel close];
            completion(nil, error);
        } else {
            // succ
            port.connectedChannel = channel;
            completion(channel, nil);
        }
    }];
}

- (void)registerWithAppID:(uint32_t)appID delegate:(id<KKConnectorClientDelegate>)delegate {
    self.appID = appID;
    self.delegate = delegate;
}

- (BOOL)isServerVersionValid:(NSString *)serverVersion {
    if ([self.delegate respondsToSelector:@selector(validateKKConnectorServerProtocolVersion:)]) {
        return [self.delegate validateKKConnectorServerProtocolVersion:serverVersion];
    } else {
        return NO;
    }
}

- (void)requestWithChannel:(PTChannel *)channel header:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body timeoutInterval:(NSTimeInterval)timeoutInterval succ:(void (^)(NSObject * _Nullable data))succBlock fail:(void (^)(NSError *error))failBlock completion:(void (^)(void))completionBlock {
    if (!channel) {
        NSAssert(NO, @"");
        if (failBlock) {
            failBlock(KKConnectorError.inner);
        }
        return;
    }
    if (!channel.isConnected) {
        if (failBlock) {
            failBlock(KKConnectorError.noConnect);
        }
        return;
    }
    if (![header isEqualToString:KKConnectorHeaderPing]) {
        // 检查是否有相同 command 的旧请求尚在进行中，如果有则移除之前的旧请求（旧请求会被报告 error）
        NSMutableArray<KKConnectorRequestKeeper *> *uselessKeepers = [NSMutableArray array];
        [channel.keepers enumerateObjectsUsingBlock:^(KKConnectorRequestKeeper * _Nonnull keeper, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([keeper.header isEqualToString:header]) {
                [uselessKeepers addObject:keeper];
            }
        }];
        [uselessKeepers enumerateObjectsUsingBlock:^(KKConnectorRequestKeeper * _Nonnull keeper, NSUInteger idx, BOOL * _Nonnull stop) {
            if (keeper.failBlock) {
                keeper.failBlock(KKConnectorError.repeatingCommand);
            }
            [keeper endTimeoutCount];
            [channel.keepers removeObject:keeper];
            
            NSLog(@"KKConnector - will discard request, command:%@", keeper.header);
        }];
    }
    
    KKConnectorRequestKeeper *keeper = [[KKConnectorRequestKeeper alloc] init];
    keeper.header = header;
    keeper.tag = (uint32_t)[[NSDate date] timeIntervalSince1970];
    keeper.succBlock = succBlock;
    keeper.failBlock = failBlock;
    keeper.completionBlock = completionBlock;
    keeper.timeoutInterval = timeoutInterval;
    __weak PTChannel *weakChannel = channel;
    keeper.timeoutBlock = ^(KKConnectorRequestKeeper *selfKeeper) {
        selfKeeper.failBlock(KKConnectorError.requestTimeout);
        [weakChannel.keepers removeObject:selfKeeper];
    };
    
    KKConnectorRequest *request = [KKConnectorRequest new];
    request.header = header;
    request.body = body;
    NSError *archiveError = nil;
    dispatch_data_t payload = [[NSKeyedArchiver archivedDataWithRootObject:request requiringSecureCoding:YES error:&archiveError] createReferencingDispatchData];
    if (archiveError) {
        NSAssert(NO, @"");
    }
    [channel sendFrameOfType:self.appID tag:keeper.tag withPayload:payload callback:^(NSError *error) {
        if (error) {
            if (failBlock) {
                failBlock(KKConnectorError.inner);
            }
        } else {
            // 成功发出了该 request
            if (!channel.keepers) {
                channel.keepers = [NSMutableArray array];
            }
            [channel.keepers addObject:keeper];
            [keeper resetTimeoutCount];
        }
    }];
}

- (void)pushInChannel:(PTChannel *)channel header:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body {
    if (!channel || !channel.isConnected) {
        return;
    }
    KKConnectorRequest *request = [KKConnectorRequest new];
    request.header = header;
    request.body = body;
    NSError *archiveError = nil;
    dispatch_data_t payload = [[NSKeyedArchiver archivedDataWithRootObject:request requiringSecureCoding:YES error:&archiveError] createReferencingDispatchData];
    if (archiveError) {
        NSAssert(NO, @"");
    }
    [channel sendFrameOfType:self.appID tag:0 withPayload:payload callback:^(NSError *error) {
        if (error) {
            NSLog(@"[KKConnector] Push failed. Header: %@, error: %@", header, error);
        }
    }];
}

- (void)cancelRequestInChannel:(PTChannel *)channel header:(NSString *)header {
    NSLog(@"[KKConnector] Cancel request. Header: %@", header);

    if (!channel) {
        return;
    }
    KKConnectorRequestKeeper *keeper = [channel queryKeeperWithHeader:header];
    if (!keeper) {
        return;
    }
    [keeper endTimeoutCount];
    [channel.keepers removeObject:keeper];
    if (keeper.completionBlock) {
        keeper.completionBlock();
    }
}

- (KKConnectorApp *)queryAppWithChannel:(PTChannel *)channel {
    for (KKConnectorApp *app in self.foundApps) {
        if (app.channel == channel) {
            return app;
        }
    }
    return nil;
}

#pragma mark - <PTChannelDelegate>

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    uint32_t appID = type;
    if (appID != self.appID) {
        return NO;
    }

    if (tag == KKConnectorTagForPush) {
        return YES;
    }
    
    KKConnectorRequestKeeper *keeper = [channel queryKeeperWithTag:tag];
    if (keeper == nil) {
        NSLog(@"KKConnector - will refuse, type:%@, tag:%@", @(type), @(tag));
        return NO;
    } else {
        return YES;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    if (tag == KKConnectorTagForPush) {
        KKConnectorApp *app = [self queryAppWithChannel:channel];
        if (!app) {
            NSAssert(NO, @"");
            return;
        }
        
        NSData *data = [NSData dataWithContentsOfDispatchData:payload.dispatchData];
        NSError *unarchiveError = nil;
        KKConnectorRequest *request = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:&unarchiveError];
        if (unarchiveError) {
            NSAssert(NO, @"");
            return;
        }
        if (![request isKindOfClass:[KKConnectorRequest class]]) {
            NSAssert(NO, @"");
            return;
        }
        [app.delegate kkConnectorApp:app didReceivePushWithHeader:request.header body:request.body];
        return;
    }
    KKConnectorRequestKeeper *keeper = [channel queryKeeperWithTag:tag];
    if (!keeper) {
        // 也许在 shouldAcceptFrameOfType 和 didReceiveFrame 两个时机之间，该 request 因为超时而被销毁了？有点玄学但确实偶尔会走到这里。
        return;
    }
    NSData *data = [NSData dataWithContentsOfDispatchData:payload.dispatchData];
    NSError *unarchiveError = nil;
    KKConnectorResponse *response = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:&unarchiveError];
    if (unarchiveError) {
        [keeper endTimeoutCount];
        [channel.keepers removeObject:keeper];
        
        NSLog(@"unarchiveError:%@", unarchiveError);
        NSAssert(NO, @"");
        if (keeper.failBlock) {
            keeper.failBlock(KKConnectorError.inner);
        }
        return;
    }
    
    if (response.hasError) {
        [keeper endTimeoutCount];
        [channel.keepers removeObject:keeper];

        NSError *error = [NSError errorWithDomain:KKConnectorErrorDomain code:response.errorCode userInfo:@{NSLocalizedDescriptionKey:response.errorDescription}];
        if (keeper.failBlock) {
            keeper.failBlock(error);
        }
        
        NSLog(@"KKConnector - request fail：%@", error);
        return;
    }
    
    if (keeper.succBlock) {
        NSObject *body = [response body];
        keeper.succBlock(body);
    }
    
    keeper.receivedDataCount += response.thisSize;
    if (keeper.receivedDataCount < response.totalSize) {
        // 没收完，继续接收后续请求。每收到一次 response 则重置 timeout 倒计时
        [keeper resetTimeoutCount];
    } else {
        // 收完了
        [keeper endTimeoutCount];
        [channel.keepers removeObject:keeper];
        if (keeper.completionBlock) {
            keeper.completionBlock();
        }
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    // iOS 客户端断开
    [self.allSimulatorPorts enumerateObjectsUsingBlock:^(KKConnectorSimulatorPort * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
        if (port.connectedChannel == channel) {
            port.connectedChannel = nil;
        }
    }];
    [self.allUSBPorts enumerateObjectsUsingBlock:^(KKConnectorUSBPort * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
        if (port.connectedChannel == channel) {
            port.connectedChannel = nil;
        }
    }];
//    [self.channelWillEnd sendNext:channel];
    
    [channel close];
}

@end
