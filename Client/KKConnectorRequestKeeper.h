//
//  KKConnectorRequestKeeper.h
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import <Foundation/Foundation.h>

@class KKConnectorRequestKeeper;

@interface KKConnectorRequestKeeper : NSObject

@property(nonatomic, copy) NSString *header;

@property(nonatomic, assign) uint32_t tag;

@property(nonatomic, assign) NSUInteger receivedDataCount;

/// 每一次收到返回数据时都会调用到这里。换句话说，如果一个请求含有多次返回，则这个 block 会被调用多次
@property(nonatomic, copy) void (^succBlock)(NSObject *);

/// 收到全局返回数据时会调用到这里，如果失败了则不会调用到这里。
@property(nonatomic, copy) void (^completionBlock)(void);

/// 遇到错误时会调用到这里
@property(nonatomic, copy) void (^failBlock)(NSError *);

/**
 调用 resetTimeoutCount 开始倒计时，如果 timeoutInterval 时间内没有通过 endTimeoutCount 结束倒计时，则 timeoutBlock 会被调用
 */

/// 超时时间，必须先设置该属性
@property(nonatomic, assign) NSTimeInterval timeoutInterval;
/// 超时后，该 block 会被调用
@property(nonatomic, copy) void (^timeoutBlock)(KKConnectorRequestKeeper *request);
/// 开始或重设倒计时
- (void)resetTimeoutCount;
/// 结束倒计时。在试图销毁该 LKConnectionRequest 对象前必须先调用该方法结束倒计时
- (void)endTimeoutCount;

@end
