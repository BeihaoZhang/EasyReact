//
//  ERDealayTransform.h
//  EasyReact
//
//  Created by nero on 2017/12/26.
//

#import <EasyReact/ERTransform.h>

NS_ASSUME_NONNULL_BEGIN

@interface ERDelayTransform : ERTransform

- (instancetype)initWithDelay:(NSTimeInterval)timeInterval queue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
