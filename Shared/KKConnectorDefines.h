//
//  LookinMessageProtocol.h
//  Lookin
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

#import <Foundation/Foundation.h>

#pragma mark - Connection

/// Server 在真机上会依次尝试监听下面这一批端口
static const int KKConnectorUSBPortStart = 47185;
static const int KKConnectorUSBPortEnd = 47189;

/// Server 在模拟器中会依次尝试监听下面这一批端口
static const int KKConnectorSimPortStart = 47190;
static const int KKConnectorSimPortEnd = 47194;

/// KKConnector 内部用来表示 Ping 请求，因此业务不能使用这个字符串作为 request header
static NSString * const KKConnectorHeaderPing = @"KKConnectorPing";

/// 该 tag 表示这个请求属于 Push，无需回复
static const int KKConnectorTagForPush = 1;

#pragma mark - Error

static NSString * const KKConnectorErrorDomain = @"KKConnector";

enum {
    /// KKConnector 内部逻辑错误
    KKConnectorError_Inner = -7000001,
    /// 连接已断开
    KKConnectorError_NoConnect = -7000002,
    /// server app 主动报告处于 inactive 状态
    KKConnectorError_BackgroundState = -7000003,
    /// 由于有 command 相同但更新的 request，因此这个旧的被废弃
    KKConnectorError_RepeatingCommand = -7000004,
    /// 超时未收到回复
    KKConnectorError_RequestTimeout = -7000005,
    /// server app 端自己的业务逻辑
    KKConnectorError_ServerAppLogic = -7000006,
    /// server 和 client 的业务 protocol version 不一致
    KKConnectorError_ProtocolVersionNotMatched = -7000007
};

