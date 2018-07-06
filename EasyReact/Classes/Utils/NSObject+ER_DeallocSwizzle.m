/**
 * Beijing Sankuai Online Technology Co.,Ltd (Meituan)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#import "NSObject+ER_DeallocSwizzle.h"
#import "ERCancelableBag.h"
#import "ERBlockCancelable.h"
#import "ERMetaMacros.h"
@import ObjectiveC.runtime;
@import ObjectiveC.message;

static const void *ERObjectDeallocBagKey = &ERObjectDeallocBagKey;
static void swizzleDeallocIfNeeded(Class classToSwizzle);

@implementation NSObject (ER_DeallocSwizzling)

- (ERCancelableBag *)er_deallocCancelBag {
    ERCancelableBag *cancelableBag = objc_getAssociatedObject(self, ERObjectDeallocBagKey);
    
    if (!cancelableBag) {
        @synchronized(self) {
            cancelableBag = objc_getAssociatedObject(self, ERObjectDeallocBagKey);
            if (!cancelableBag) {
                swizzleDeallocIfNeeded(self.class);
                cancelableBag = [ERCancelableBag bag];
                objc_setAssociatedObject(self, ERObjectDeallocBagKey, cancelableBag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return cancelableBag;
}

- (id<ERCancelable>)er_listenDealloc:(void (^)(void))deallocBlock {
    NSCParameterAssert(deallocBlock);
    if (!deallocBlock) {
        return [[ERBlockCancelable alloc] initWithBlock:^{}];
    }
    
    ERBlockCancelable *deallocCancelable = [[ERBlockCancelable alloc] initWithBlock:deallocBlock];
    [self.er_deallocCancelBag addCancelable:deallocCancelable];
    @er_weakify(self)
    return [[ERBlockCancelable alloc] initWithBlock:^{
        @er_strongify(self)
        [self.er_deallocCancelBag removeCancelable:deallocCancelable];
    }];
}

@end

static NSMutableSet *swizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    
    return swizzledClasses;
}

static void swizzleDeallocIfNeeded(Class classToSwizzle) {
    @synchronized (swizzledClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([swizzledClasses() containsObject:className]) return;
        
        SEL deallocSelector = sel_registerName("dealloc");
        
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        
        id newDealloc = ^(__unsafe_unretained id self) {
            ERCancelableBag *cancelableBag = objc_getAssociatedObject(self, ERObjectDeallocBagKey);
            [cancelableBag cancel];
            objc_setAssociatedObject(self, ERObjectDeallocBagKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };
                
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        
        [swizzledClasses() addObject:className];
    }
}
