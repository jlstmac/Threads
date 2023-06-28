//
//  ViewController.m
//  Thread
//
//  Created by Jiang LinShan on 2023/6/28.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self problem1GCD];
//    [self problem1Operation];
    
//    [self propblem2GCD];
    [self propblem2Operation];
}

//问题1:A B C D E F六个任务，AB执行完之后才能执行D，BC执行完之后才能执行E, DE执行完之后才能执行F，可以并发，整体尽快执行完，ABC之间没有依赖，DF之间没有依赖。
- (void)problem1GCD {
    dispatch_group_t groupD = dispatch_group_create(); //groupD用来监控A和B任务
    dispatch_group_t groupE = dispatch_group_create(); //groupE用来监控B和C任务
    dispatch_group_t groupF = dispatch_group_create(); //groupF用来监控D和E任务
    
    ///关键是使用dispatch_group_enter和dispatch_group_leave两个函数，这两个函数必须成对出现，且先enter再leave，用来监控一个任务的进入和执行完毕。多套enter和leave实现整组的监控。

    dispatch_group_enter(groupD);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        NSLog(@"A");
        dispatch_group_leave(groupD);
    });
    
    dispatch_group_enter(groupD);
    dispatch_group_enter(groupE);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"B");
        dispatch_group_leave(groupD);
        dispatch_group_leave(groupE);
    });
    
    dispatch_group_enter(groupE);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"C");
        dispatch_group_leave(groupE);
    });
    
    dispatch_group_enter(groupF);
    dispatch_group_notify(groupD, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        NSLog(@"D");
        dispatch_group_leave(groupF);

    });
    
    dispatch_group_enter(groupF);
    dispatch_group_notify(groupE, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"E");
        dispatch_group_leave(groupF);
    });
    
    dispatch_group_notify(groupF, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"F");
    });
}

- (void)problem1Operation {
    // 用NSBlockOperation创建任务
    NSBlockOperation* blockA = [NSBlockOperation blockOperationWithBlock:^{
        sleep(1);
        NSLog(@"A");
    }];
    NSBlockOperation* blockB = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"B");
    }];
    NSBlockOperation* blockC = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"C");
    }];
    NSBlockOperation* blockD = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"D");
    }];
    NSBlockOperation* blockE = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"E");
    }];
    NSBlockOperation* blockF = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"F");
    }];
    
    // 设置任务之间的依赖关系
    [blockD addDependency:blockA];
    [blockD addDependency:blockB];
    
    [blockE addDependency:blockB];
    [blockE addDependency:blockC];
    
    [blockF addDependency:blockD];
    [blockF addDependency:blockE];
    
    // 把所有任务加到queue中执行
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue addOperation:blockA];
    [queue addOperation:blockB];
    [queue addOperation:blockC];
    [queue addOperation:blockD];
    [queue addOperation:blockE];
    [queue addOperation:blockF];

}


//问题2: 假如现在有1w个任务需要执行，并且在全部执行完成之后进行一个提示，该怎么做（group可以轻松实现，但是可能会导致大量线程创建，形成资源浪费）？如果需要设置最大并发量为10应该怎么做？
- (void)propblem2GCD {
    const int MAXCOUNT = 10000;
    const int MAXASYNCCOUNT = 10;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(MAXASYNCCOUNT);
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < MAXCOUNT; i++) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            NSLog(@"%d",i);
            dispatch_semaphore_signal(semaphore);
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"执行完毕");
    });
}

- (void)propblem2Operation {
    NSOperationQueue *queue = NSOperationQueue.new;
    queue.maxConcurrentOperationCount = 10;
    for (int i = 0; i < 10000; i++) {
        [queue addOperation:[NSBlockOperation blockOperationWithBlock:^{
//            sleep(1);
            NSLog(@"%d",i);
        }]];
    }
    [queue addBarrierBlock:^{
        NSLog(@"执行完毕");
    }];
    
}
@end
