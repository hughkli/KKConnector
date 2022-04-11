//
//  KKConnectorApp.h
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/10.
//

#import <Foundation/Foundation.h>

@class PTChannel, KKConnectorApp;

NS_ASSUME_NONNULL_BEGIN

@protocol KKConnectorAppDeleate <NSObject>

- (void)kkConnectorApp:(KKConnectorApp *)app didReceivePushWithHeader:(NSString *)header body:(nullable id)body;

@end

@interface KKConnectorApp : NSObject

@property(nonatomic, weak) id<KKConnectorAppDeleate> delegate;

- (instancetype)initWithChannel:(PTChannel *)channel serverProtocolVersion:(NSString *)serverProtocolVersion sessionID:(NSString *)sessionID;

@property(nonatomic, strong, readonly) PTChannel *channel;

@property(nonatomic, copy, readonly) NSString *serverProtocolVersion;

/// 每次 server app 被启动时都会随机生成一个 sessionID，这个 ID 不会变化，直到 server app 被 kill 掉
@property(nonatomic, copy, readonly) NSString *sessionID;

- (BOOL)isConnected;

- (BOOL)isServerVersionValid;

- (void)requestWithHeader:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body succBlock:(void (^)(NSObject * _Nullable result))succBlock completionBlock:(void (^)(void))completionBlock errorBlock:(void (^)(NSError * error))errorBlock;

/// 向 Server 端发送数据，但不需要 Server 端回复，也不关心该数据是否真的发送成功
- (void)pushWithHeader:(NSString *)header body:(nullable NSObject<NSSecureCoding> *)body;

/// 不再接收已经发出去的某个请求的后续 Server 端回复，该请求的 completionBlock 会被调用
/// Server 端不会得知 Client 端取消了该请求
- (void)cancelRequestWithHeader:(NSString *)header;

@end

NS_ASSUME_NONNULL_END
