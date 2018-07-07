# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 2.2.0 - 2018-07-07

### Added

- Add documents for english language.

### Changed

- Change Dependency to EasyFoundation.

### Fixed

- Optimize performance.

## 2.1.0 

- Fixed internal memory leak in EZR_PATH
- Rename the EZRNodeTransform Series to Edge
- Added - [EZRNode combine:], - [EZRNode merge:], - [EZRNode zip:] API
- Added - [EZRNode switch:], - [EZRNode switchMap:], - [EZRNode if:], - [EZRNode else:], - [EZRNode case:] API
- Fixed issue that skip take flattenMap operation reuse Transform old data
- Updated EasyTuple 1.10 and EasySequence 1.2.1

## 2.0.0

- Use EasySequence instead of System Container
- Fixed a bug could cause the listening fail by the hash conflict
- Rename prefix ER to EZR
- Implement NSObject `ezr_toNode` and ʻezr_toMutableNode`
- Added `getValue` `valueWith:` method in EZRNode + Value Category 
- Implement the EZRNode `scan:reduce:` method
- Modified EZRNode as immutable object, EZRMutableNode as mutable object
- Reconstructed the graph theory memory management logic
- Changed the Listen interface
- Changed Ztuple dependency to EasyTuple
- Take out Utils related class, it would migrate to EasySequence in the future
- Add documents

## 1.3.2

- Modified Node memory leak problem
- Modified DelivedOnMainQueue implementation

## 1.3.1

- Added `er_deallocCancelBag` interface
- Modified the implementation of `er_listenDealloc`

## 1.3.0

- Added `delay` `then` `select:` interface
- Rename throttle to throttleOnMainQueue

## 1.2.2

- Added `clean` interface

## 1.2.1

- Added `fork` interface

## 1.2.0

- Added `deliverOn:(dispatch_queue_t)queue` and `deliverOnMainQueue;` interfaces

## 1.1.0

- Rename syncTo to SyncWith

## 1.0.0

- First Version
