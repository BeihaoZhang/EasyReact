# Change Log

## 2.1.0 

- 修复了 EZR_PATH 内部的内存泄露问题
- 重命名 EZRNodeTransform 系列为 Edge
- 新增 - [EZRNode combine:], - [EZRNode merge:], - [EZRNode zip:] API
- 新增 - [EZRNode switch:], - [EZRNode switchMap:], - [EZRNode if:], - [EZRNode else:], - [EZRNode case:] API
- 修复了 skip  take  flattenMap 重用 Transform时的保存的旧数据问题
- 更新了 EasyTuple 1.10 和  EasySequence 1.2.1

## 2.0.0 

- 使用 EasySequence 替代系统容器
- 修复hash冲突导致监听失败的bug
-  重命名前缀 ER 为 EZR
-  实现 NSObject `ezr_toNode`  和 `ezr_toMutableNode`
-  EZRNode + Value 分类 新增 `getValue` `valueWith:` 方法
-  实现 EZRNode `scan:reduce:` 方法
-  修改 EZRNode 为不可变对象 EZRMutableNode为可变对象
-  重构了图论的内存管理逻辑
-  修改了 Listen 接口
-  Ztuple 依赖 修改为 EasyTuple
-  取出Utils 相关类 后续迁移至 EasySequence
-  添加文档 

## 1.3.2

-  修改 Node 内存泄露问题
-  修改 DelivedOnMainQueue 实现

## 1.3.1

-  新增 `er_deallocCancelBag` 接口
-  修改 `er_listenDealloc` 的实现

## 1.3.0

-  新增 `delay` `then` `select:` 接口
-  重命名throttle到throttleOnMainQueue

## 1.2.2

-  新增 `clean` 接口

## 1.2.1

-  新增 `fork` 接口

## 1.2.0

-  新增 `deliverOn:(dispatch_queue_t)queue` 和 `deliverOnMainQueue;` 接口

## 1.1.0

-  重命名syncTo到SyncWith


## 1.0.0

Initial release of EasyReact.
