//
//  KKConnectorClient.h
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/10.
//

#import <Foundation/Foundation.h>

@class KKConnectorApp;

/**
 iOS 是 Server 端，macOS 是 Client 端
 
 - 把 app 退到后台不会 kill 掉 server channel，仍旧会占用着端口（但可能无法执行代码）
 - 把 app kill 掉后，server channel 也会被 kill，端口占用会被释放
 
 - 一台电脑上的所有模拟器里的所有 app 共享同一批端口，比如依次启动“模拟器 A 的 app1”、“模拟器 A 的 app2”、“模拟器 B 的 app3”，则它们依次会占用 47164、47165、47166 这几个端口
 - 一台真机上的所有 app 共享同一批端口，比如依次启动“真机 A 的 app1”、“真机 A 的 app2”、“真机 B 的 app3”，则它们依次会占用 47175、47176、47175（注意不是 47177）这几个端口
 
 */

NS_ASSUME_NONNULL_BEGIN

@protocol KKConnectorClientDelegate <NSObject>

- (BOOL)validateKKConnectorServerProtocolVersion:(NSString *)serverProtocolVersion;

- (void)kkConnectorClientDidReceivePushWithHeader:(NSString *)header body:(nullable id)body;


@end

@interface KKConnectorClient : NSObject

+ (instancetype)sharedInstance;

/// delegate 会被 KKConnectorClient 强持有
- (void)registerWithAppID:(uint32_t)appID delegate:(id<KKConnectorClientDelegate>)delegate;

/// 搜索可以响应的 App 列表，data 为 Array<KKConnectorApp>，ping 失败的 app 不会出现在 data 里面
/// 该方法不会 sendError
- (void)searchApps:(void (^)(NSArray<KKConnectorApp *> *))completion;

@end

NS_ASSUME_NONNULL_END
