//
//  ERDealayTransform.m
//  EasyReact
//
//  Created by nero on 2017/12/26.
//

#import "ERDelayTransform.h"

@implementation ERDelayTransform {
    NSTimeInterval _delayTimeInterval;
    dispatch_queue_t _queue;
}

- (instancetype)initWithDelay:(NSTimeInterval)timeInterval queue:(nonnull dispatch_queue_t)queue{
    NSParameterAssert(timeInterval > 0);
    NSParameterAssert(queue);
    if (self = [super init]) {
        _delayTimeInterval = timeInterval;
        _queue = queue;
        [super setName:@"Delay"];
    }
    return self;
}


- (void)next:(id)value from:(ERSenderList *)senderList {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delayTimeInterval * NSEC_PER_SEC)), _queue, ^{
        [super next:value from:senderList];
    });
}

@end
