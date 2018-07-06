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

#import <Foundation/Foundation.h>

#ifndef ER_META_MACRO_H
#define ER_META_MACRO_H

#define ER_CONCAT(A, B)             ER_CONCAT_(A, B)
#define ER_CONCAT_(A, B)            A ## B

#define ER_LOCK_TYPE                dispatch_semaphore_t
#define ER_LOCK_DEF(LOCK)           dispatch_semaphore_t LOCK
#define ER_LOCK_INIT(LOCK)          LOCK = dispatch_semaphore_create(1)
#define ER_LOCK(LOCK)               dispatch_semaphore_wait(LOCK, DISPATCH_TIME_FOREVER)
#define ER_UNLOCK(LOCK)             dispatch_semaphore_signal(LOCK)

static inline void ER_unlock(ER_LOCK_TYPE *lock) {
    ER_UNLOCK(*lock);
}

#define ER_SCOPELOCK(LOCK)          ER_LOCK(LOCK);ER_LOCK_TYPE ER_CONCAT(auto_lock_, __LINE__) __attribute__((cleanup(ER_unlock), unused)) = LOCK



#endif //ER_META_MACRO_H
