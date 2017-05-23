//
//  ViewController.m
//  MPProcessMessageServer
//
//  Created by mopellet on 2017/5/23.
//  Copyright © 2017年 eegsmart. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
@interface ViewController () <GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *_serverSocket;
}
@property(strong,nonatomic)NSMutableArray *clientSocket;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _clientSocket = [NSMutableArray array];
    //创建服务端的socket，注意这里的是初始化的同时已经指定了delegate
    _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self startChatServer];
}

-(void)startChatServer{
    //打开监听端口
    NSError *err;
    [_serverSocket acceptOnPort:12345 error:&err];
    if (!err) {
        NSLog(@"Server 服务开启成功");
    }else{
        NSLog(@"Server 服务开启失败");
    }
}
#pragma mark 有客户端建立连接的时候调用
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    //sock为服务端的socket，服务端的socket只负责客户端的连接，不负责数据的读取。   newSocket为客户端的socket    NSLog(@"服务端的socket %p 客户端的socket %p",sock,newSocket);
    //保存客户端的socket，如果不保存，服务器会自动断开与客户端的连接（客户端那边会报断开连接的log）
    NSLog(@"Server %s",__func__);
    [self.clientSocket addObject:newSocket];
    
    //newSocket为客户端的Socket。这里读取数据
    [newSocket readDataWithTimeout:-1 tag:100];
}
#pragma mark 服务器写数据给客户端
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"Server %s",__func__);
    [sock readDataWithTimeout:-1 tag:100];
}

#pragma mark 接收客户端传递过来的数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //sock为客户端的socket
    NSLog(@"Server 客户端的socket %p",sock);
    //接收到数据
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Server length:%ld",receiverStr.length);
    // 把回车和换行字符去掉，接收到的字符串有时候包括这2个，导致判断quit指令的时候判断不相等
    receiverStr = [receiverStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    receiverStr = [receiverStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    //判断是登录指令还是发送聊天数据的指令。这些指令都是自定义的
    //登录指令
    if([receiverStr hasPrefix:@"iam:"]){        // 获取用户名
        NSString *user = [receiverStr componentsSeparatedByString:@":"][1];
        // 响应给客户端的数据
        NSString *respStr = [user stringByAppendingString:@"has joined"];
        [sock writeData:[respStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    }
    //聊天指令
    if ([receiverStr hasPrefix:@"msg:"]) {
        //截取聊天消息
        NSString *msg = [receiverStr componentsSeparatedByString:@":"][1];
        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    }
    //quit指令
    if ([receiverStr isEqualToString:@"quit"]) {
        //断开连接
        [sock disconnect];
        //移除socket
        [self.clientSocket removeObject:sock];
    }
    NSLog(@"Server %s",__func__);
}

@end
