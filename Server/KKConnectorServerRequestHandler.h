//
//  KKConnectorServerRequestHandler.h
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKConnectorServerRequestHandler : NSObject

- (instancetype)initWithAppID:(uint32_t)appID requestTag:(uint32_t)tag;

/// 回复一个错误，客户端收到后会中止整个请求
/// 可以使用 errorCode 和 errorDescription 来描述错误，客户端可以分别从收到的 NSError 的 code 与 localizedDescription 属性中取出来
/// @Warning 业务不要使用 -7000001 ~ -7000020 范围内的值作为 errorCode，因为它们已经被 KKConnector 内部占用了
- (void)errorWithCode:(int)errorCode description:(nullable NSString *)errorDescription;

/// 如果只需要一次 response 则用这个方法
- (void)just:(NSObject<NSSecureCoding> * _Nullable)data;

/// 如果数据量比较大需要拆成多次 response，则先调用 startWithTotalSize 设置总大小，然后调用 respond:thisSize: 分别返回，当客户端收到的 size 的总和达到最开始设置的 totalSize 时则认定回复完成
- (void)startWithTotalSize:(int)size;
- (void)respond:(NSObject<NSCoding> *)data thisSize:(int)size;

@end

NS_ASSUME_NONNULL_END
