//
//  ViewController.m
//  MPProcessMessageClient
//
//  Created by mopellet on 2017/5/23.
//  Copyright © 2017年 eegsmart. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
@interface ViewController ()<GCDAsyncSocketDelegate>
{
     GCDAsyncSocket *_clientSocket;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self connectToServer];
}

- (void) connectToServer{
    //1.主机与端口号
    NSString *host = @"127.0.0.1";
    int port = 12345;
    
    //初始化socket，这里有两种方式。分别为是主/子线程中运行socket。根据项目不同而定
    _clientSocket = [[GCDAsyncSocket alloc]
                     initWithDelegate:self delegateQueue:dispatch_get_main_queue()];//这种是在主线程中运行
    //_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)]; 这种是在子线程中运行
    
    //开始连接
    NSError *error = nil;
    if (![_clientSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"Client Error connecting: %@", error);
    }
    
}


-(IBAction)login:(id)sender{
    //登录String
    NSString *loginStr = @"iam:I am login!";
    NSData *loginData = [loginStr dataUsingEncoding: NSUTF8StringEncoding];
    //发送登录指令。-1表示不超时。tag200表示这个指令的标识，很大用处
    [_clientSocket writeData: loginData withTimeout:-1 tag:200];
}

//发送聊天数据
-(IBAction) sendMsg: (id)sender{
    NSString *sendMsg = @"msg:I send message to u!";
    NSData *sendData = [sendMsg dataUsingEncoding:NSUTF8StringEncoding];
    [_clientSocket writeData:sendData withTimeout:-1 tag:201];
}

#pragma mark -socket的代理

#pragma mark 连接成功

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    //连接成功
    NSLog(@"Client %s",__func__);
}

#pragma mark 断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (err) {
        NSLog(@"Client 连接失败");
    }else{
        NSLog(@"Client 正常断开");
    }
}

#pragma mark 数据发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"Client %s",__func__);
    //发送完数据手动读取
    [sock readDataWithTimeout:-1 tag:tag];
}

#pragma mark 读取数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (tag == 200) {
        //登录指令
    }else if(tag == 201){
        //聊天数据
    }
    NSLog(@"Client %s %@",__func__,receiverStr);
}

@end
