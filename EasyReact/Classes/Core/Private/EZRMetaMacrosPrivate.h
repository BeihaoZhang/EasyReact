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

@import Foundation;

#ifndef EZR_META_MACRO_H
#define EZR_META_MACRO_H

#define EZR_CONCAT(A, B)             EZR_CONCAT_(A, B)
#define EZR_CONCAT_(A, B)            A ## B

#define EZR_LOCK_TYPE                dispatch_semaphore_t
#define EZR_LOCK_DEF(LOCK)           dispatch_semaphore_t LOCK
#define EZR_LOCK_INIT(LOCK)          LOCK = dispatch_semaphore_create(1)
#define EZR_LOCK(LOCK)               dispatch_semaphore_wait(LOCK, DISPATCH_TIME_FOREVER)
#define EZR_UNLOCK(LOCK)             dispatch_semaphore_signal(LOCK)

static inline void EZR_unlock(EZR_LOCK_TYPE *lock) {
    EZR_UNLOCK(*lock);
}

#define EZR_SCOPELOCK(LOCK)          EZR_LOCK(LOCK);EZR_LOCK_TYPE EZR_CONCAT(auto_lock_, __LINE__) __attribute__((cleanup(EZR_unlock), unused)) = LOCK

// branch prediction
#define EZR_BRANCH_PREDICTION

#ifdef EZR_BRANCH_PREDICTION
#define EZR_Likely(x)       (__builtin_expect(!!(x), 1))
#define EZR_Unlikely(x)     (__builtin_expect(!!(x), 0))
#define EZR_LikelyYES(x)    (__builtin_expect(x, YES))
#define EZR_LikelyNO(x)     (__builtin_expect(x, NO))
#else
#define EZR_Likely(x)       (x)
#define EZR_Unlikely(x)     (x)
#define EZR_LikelyYES(x)    (x)
#define EZR_LikelyNO(x)     (x)
#endif

#endif //EZR_META_MACRO_H
