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

#import <EasyFoundation/EasyFoundation.h>

#define _EZRCombine(...)  ((EZ_CONCAT(EZRMapEachNode, EZ_ARG_COUNT(__VA_ARGS__)) *)[EZRNode combine:@[__VA_ARGS__]])

#define _EZRZip(...)  ((EZ_CONCAT(EZRMapEachNode, EZ_ARG_COUNT(__VA_ARGS__)) *)[EZRNode zip:@[__VA_ARGS__]])

#define _EZR_BLOCK_ARG(index)         EZ_CONCAT(arg, index)
#define _EZR_BLOCK_ARG_DEF(index)     id EZ_CONCAT(arg, index)

#define _EZR_BLOCK_DEF(N)                id (^)(EZ_FOR_COMMA(N, _EZR_BLOCK_ARG_DEF))

#define _EZR_DEF_REDUCE_VALUE(N)                                 \
@interface EZ_CONCAT(EZRMapEachNode, N) : EZRNode                  \
- (EZRNode *)mapEach:(_EZR_BLOCK_DEF(N))block;                    \
@end

#define _EZR_DEF_REDUCE_VALUE_ITER(index)             _EZR_DEF_REDUCE_VALUE(EZ_INC(index))

#define EZR_MapEachFakeInterfaceDef(N)           EZ_FOR(N, _EZR_DEF_REDUCE_VALUE_ITER, ;)

#define _EZR_KeyPath(OBJ, PATH)  (((void)(NO && ((void)OBJ.PATH, NO)), @# PATH))

#define _EZR_PATH(TARGET, KEYPATH)               TARGET.ezr_path[_EZR_KeyPath(TARGET, KEYPATH)]


#define EZR_THROW(NAME, REASON, INFO)                            \
    NSException *exception = [[NSException alloc] initWithName:NAME reason:REASON userInfo:INFO]; @throw exception;

#define ezr_weakify(...)                                         \
    ezr_keywordify                                               \
    EZ_FOR_EACH(ezr_weakify_, ,__VA_ARGS__)


#define ezr_strongify(...)                                       \
    ezr_keywordify                                               \
    _Pragma("clang diagnostic push")                            \
    _Pragma("clang diagnostic ignored \"-Wshadow\"")            \
    EZ_FOR_EACH(ezr_strongify_, , __VA_ARGS__)                     \
    _Pragma("clang diagnostic pop")


#define ezr_weakify_(INDEX, VAR)                                 \
    __weak __typeof__(VAR) EZ_CONCAT(VAR, _weak_) = (VAR);

#define ezr_strongify_(INDEX, VAR)                               \
    __strong __typeof__(VAR) VAR = EZ_CONCAT(VAR, _weak_);

#if DEBUG
#define ezr_keywordify autoreleasepool {}
#else
#define ezr_keywordify try {} @catch (...) {}
#endif

