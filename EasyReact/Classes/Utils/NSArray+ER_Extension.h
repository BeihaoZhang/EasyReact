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

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant T> (ER_Extension)

- (NSArray *)er_map:(id (^)(T value))mapBlock;

- (NSArray *)er_mapWithIndex:(id (^)(T value, NSUInteger index))mapBlock;

- (void)er_foreach:(void (^)(T value))eachBlock;

- (void)er_foreachWithIndex:(void (^)(T value, NSUInteger index))eachBlock;

- (void)er_foreachWithIndexAndStop:(void (^)(T value, NSUInteger index, BOOL *stop))eachBlock;

- (BOOL)er_any:(BOOL (^)(T value))checkBlock;

- (NSArray<T> *)er_select:(BOOL (^)(T value))checkBlock;

- (NSArray<T> *)er_reject:(BOOL (^)(T value))checkBlock;

- (nullable id)er_reduce:(id _Nullable (^)(id _Nullable operand1, T operand2))reduceBlock;

- (nullable id)er_reduceWithStartValue:(nullable id)startValue operation:(id _Nullable (^)(id _Nullable accumulator, T operand))reduceBlock;

/**
 Groups the array by the result of the block. Returns an empty dictionary if the original array is empty.

 @param groupBlock The block applyed to each item of the original array, the return value will be used as the key of the result dictionary.
 @return A dictionary where the keys are the returned values of the block, and the values are arrays of objects in the original array that correspond to the key.
 */
- (NSDictionary<id, NSArray<T> *> *)er_groupBy:(id (^)(T value))groupBlock;

+ (NSArray<NSArray *> *)er_zip:(NSArray<NSArray *> *)zippedArrays;

@end

NS_ASSUME_NONNULL_END
