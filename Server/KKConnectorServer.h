//
//  KKSConnectionManager.h
//  KKServer
//
//  Created by 李凯 on 2020/11/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KKConnectorServerRequestHandler;

@protocol KKConnectorServerDelegate <NSObject>

/// 当 Client 端发送的是 Push 类型的消息时（不需要回复）则 handler 为 nil
- (void)connectorServerDidReceiveRequestHeader:(NSString *)header body:(nullable id)body handler:(nullable KKConnectorServerRequestHandler *)handler;

@end

@interface KKConnectorServer : NSObject

+ (instancetype)sharedInstance;

- (void)registerAppID:(unsigned int)appID protocolVersion:(NSString *)protocolVersion delegate:(id<KKConnectorServerDelegate>)delegate;

/// 主动向 Client 端推送数据，不保证可以送达，Server 端也不会收到任何回复
- (void)pushWithAppID:(unsigned int)appID header:(NSString *)header body:(nullable id)body;

@end

NS_ASSUME_NONNULL_END
