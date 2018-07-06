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

#import <ZTuple/ZTuple.h>

#define _ERCombine(...)  ((Z_CONCAT(ERMapEachNode, Z_ARG_COUNT(__VA_ARGS__)) *)[ERNode combine:@[__VA_ARGS__]])

#define _ERZip(...)  ((Z_CONCAT(ERMapEachNode, Z_ARG_COUNT(__VA_ARGS__)) *)[ERNode zip:@[__VA_ARGS__]])

#define _ER_BLOCK_ARG(index)         Z_CONCAT(arg, index)
#define _ER_BLOCK_ARG_DEF(index)     id Z_CONCAT(arg, index)

#define _ER_BLOCK_DEF(N)                id (^)(Z_FOR_COMMA(N, _ER_BLOCK_ARG_DEF))

#define _ER_DEF_REDUCE_VALUE(N)                                 \
@interface Z_CONCAT(ERMapEachNode, N) : ERNode                  \
- (ERNode *)mapEach:(_ER_BLOCK_DEF(N))block;                    \
@end

#define _ER_DEF_REDUCE_VALUE_ITER(index)             _ER_DEF_REDUCE_VALUE(Z_INC(index))

#define ER_MapEachFakeInterfaceDef(N)           Z_FOR(N, _ER_DEF_REDUCE_VALUE_ITER, ;)

#define _ER_KeyPath(OBJ, PATH)  (((void)(NO && ((void)OBJ.PATH, NO)), @# PATH))

#define _ER_PATH(TARGET, KEYPATH)               TARGET.er_path[_ER_KeyPath(TARGET, KEYPATH)]


#define ER_THROW(NAME, REASON, INFO)                            \
    NSException *exception = [[NSException alloc] initWithName:NAME reason:REASON userInfo:INFO]; @throw exception;

#define er_weakify(...)                                         \
    er_keywordify                                               \
    Z_FOR_EACH(er_weakify_, ,__VA_ARGS__)


#define er_strongify(...)                                       \
    er_keywordify                                               \
    _Pragma("clang diagnostic push")                            \
    _Pragma("clang diagnostic ignored \"-Wshadow\"")            \
    Z_FOR_EACH(er_strongify_, , __VA_ARGS__)                     \
    _Pragma("clang diagnostic pop")


#define er_weakify_(INDEX, VAR)                                 \
    __weak __typeof__(VAR) Z_CONCAT(VAR, _weak_) = (VAR);

#define er_strongify_(INDEX, VAR)                               \
    __strong __typeof__(VAR) VAR = Z_CONCAT(VAR, _weak_);

#if DEBUG
#define er_keywordify autoreleasepool {}
#else
#define er_keywordify try {} @catch (...) {}
#endif

