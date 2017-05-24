# MPProcessMessage
适用于未越狱iOS设备之间的数据传输（进程间通讯）

## Usage scenario 使用场景
* 多个App之间的数据传输
* App与网页之间的数据传输

## Description 描述
* 采用Local Socket方案（TCP）创建服务端和客户端从而达到通讯效果。
* 由于原生socket过于复杂不便于理解，请先发几分钟了解下[GCDAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)。
* 本Demo基于[GCDAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)提供的解决方案。
* 示例代码部分取决于互联网，我只是搬运工。

## Main idea 主要思路
* 首先在一个App里面创建一个本地服务端（127.0.0.1）
* 在另外一个App或者网页里面创建一个客户端
* 客户端连接到服务端，即可实现通讯效果

## Usage 使用方法
### 创建服务端
```objc
//一定要在子线程里面创建服务端
    GCDAsyncSocket *serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                              delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    //打开监听端口
    NSError *err;
    [_serverSocket acceptOnPort:12345 error:&err];
    if (!err) {
        NSLog(@"Server 服务开启成功");
    }else{
        NSLog(@"Server 服务开启失败");
    }
```
### 服务端实现代理 
```objc
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

```
### 创建客户端
```objc
    //初始化socket，这里有两种方式。分别为是主/子线程中运行socket。根据项目不同而定
//这种是在主线程中运行
   GCDAsyncSocket * clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                              delegateQueue:dispatch_get_main_queue()];
    //开始连接
    NSError *error = nil;
    if (![clientSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"Client Error connecting: %@", error);
    }
```
### 实现客户端代理
```objc

#pragma mark 连接成功

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    //连接成功
    NSLog(@"Client %s",__func__);
    
    //连接成功之后可以发送消息给服务端
    
    //登录String
    NSString *loginStr = @"iam:I am login!";
    NSData *loginData = [loginStr dataUsingEncoding: NSUTF8StringEncoding];
    //发送登录指令。-1表示不超时。tag200表示这个指令的标识，很大用处
    [clientSocket writeData: loginData withTimeout:-1 tag:200];
    
    NSString *sendMsg = @"msg:I send message to u!";
    NSData *sendData = [sendMsg dataUsingEncoding:NSUTF8StringEncoding];
    [clientSocket writeData:sendData withTimeout:-1 tag:201];
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

```
### 注意事项
* 由于iOS的系统机制限制，要想服务端客户端实时通讯那，必须要App后台运行。
* 现有方案后台运行方案，获取定位，音乐播放，远程推送，后台任务等。
* 部分实例代码如下：（可替换成你项目需要的代码）
```objc
    //在AppDelegate.h中添加
    UIBackgroundTaskIdentifier taskId;

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //开启一个后台任务
    taskId = [application beginBackgroundTaskWithExpirationHandler:^{
        //结束指定的任务
        [application endBackgroundTask:taskId];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerWork:) userInfo:nil repeats:YES];
}

- (void)timerWork:(NSTimer *)timer {
    static int count = 0;
    count++;
    // 正常后台任务10分钟之后会被关闭
    if (count % 500 == 0) {
        UIApplication *application = [UIApplication sharedApplication];
        //结束旧的后台任务
        [application endBackgroundTask:taskId];
        
        //开启一个新的后台
        taskId = [application beginBackgroundTaskWithExpirationHandler:NULL];
    }
    NSLog(@"%d",count)
}

```


## 联系方式:
* WeChat : wzw351420450
* Email : mopellet@foxmail.com
* Resume : [个人简历](https://github.com/MoPellet/Resume)
