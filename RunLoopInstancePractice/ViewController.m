//
//  ViewController.m
//  RunLoopInstancePractice
//
//  Created by yurongde on 16/5/19.
//  Copyright © 2016年 yurongde. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) NSThread *myThread;
@property (nonatomic, assign) BOOL runLoopThreadDidFinishFlag;
@property dispatch_source_t timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self method1_1];
//    [self method2_2];
//    [self method3_1];
//    [self method3_2];
//    
//    [self method4_1];
//    [self runLoopAddDependance];
    [self gcdTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)method1_1 {
    while (1) {
        NSLog(@"while begin");
        // the thread be blocked here
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        NSPort *myPort = [NSPort port];
        [runLoop addPort:myPort forMode:NSDefaultRunLoopMode];
//        让线程在这里停下来
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        

//        [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        // this will not be executed
        NSLog(@"while end");
        
    }
}
- (void)method1_2 {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        while (1) {
            
            NSLog(@"while begin");
            NSRunLoop *subRunLoop = [NSRunLoop currentRunLoop];
            [subRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            NSLog(@"while end");
        }
        
        
    });
}
- (void)method3_1 {
    [self performSelector:@selector(mainThreadMethod) withObject:nil];
}
- (void)mainThreadMethod {
    NSLog(@"execute %s",__func__);
}
- (void)method3_2 {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelector:@selector(backGroundThread) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    });
}
- (void)backGroundThread{
    
    NSLog(@"%u",[NSThread isMainThread]);
    
    NSLog(@"execute %s",__FUNCTION__);
    
}

- (void)method4_1 {
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(myThreadRun) object:@"etund"];
    self.myThread = thread;
    //单纯执行完后就死了，增加一个source才不死
    [self.myThread start];
}
- (void)myThreadRun {
    NSLog(@"myThreadRun");
//    正常情况下，后台线程执行完任务之后就处于死亡状态，我们要避免这种情况的发生可以利用RunLoop，并且给它一个Source这样来保证线程依旧还在
    [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc]init] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop]run];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%@",self.myThread);
    [self performSelector:@selector(doBackGroundThreadWork) onThread:self.myThread withObject:nil waitUntilDone:NO];
}
- (void)doBackGroundThreadWork {
    NSLog(@"do some work %s",__FUNCTION__);

}
- (void)runLoopAddDependance {
    self.runLoopThreadDidFinishFlag = NO;
    
    NSLog(@"Start a New RunLoop Thread");
    NSThread *runLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(handleRunLoopThreadTask) object:nil];
    [runLoopThread start];
    
    NSLog(@"Exit handleRunLoopThreadButtonTouchUpInside");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (!_runLoopThreadDidFinishFlag) {
            self.myThread = [NSThread currentThread];
            NSLog(@"Begin RunLoop");
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            NSPort *myPort = [NSPort port];
            [runLoop addPort:myPort forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

            NSLog(@"End RunLoop");
            [self.myThread cancel];
            self.myThread = nil;
        }
    });
}
- (void)handleRunLoopThreadTask {
    NSLog(@"Enter RunLoop Thread");
    for (int i =0 ; i< 5; i++) {
        NSLog(@"In RunLoop Thread,count = %d",i);
        sleep(1);
    }
#if 0
    // 错误示范
    _runLoopThreadDidFinishFlag = YES;
    // 这个时候并不能执行线程完成之后的任务，因为Run Loop所在的线程并不知道runLoopThreadDidFinishFlag被重新赋值。Run Loop这个时候没有被任务事件源唤醒。
    // 正确的做法是使用 "selector"方法唤醒Run Loop。 即如下:#endif
    
#endif
    NSLog(@"Exit Normal Thread");
    [self performSelector:@selector(tryOnMyThread) onThread:self.myThread withObject:nil waitUntilDone:NO];
}
- (void)tryOnMyThread {
    _runLoopThreadDidFinishFlag = YES;
}

- (void)gcdTimer {
    //get the queue
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    // create timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    self.timer = timer;
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"gcdTimer");
        });
    });
    dispatch_resume(timer);
}
@end
