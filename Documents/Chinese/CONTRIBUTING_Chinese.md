# 为 EasyReact 贡献代码

我们鼓励使用者向 EasyReact 项目做贡献，共享代码的规则可以参考下面的条例。

如果你碰见了一些不明白的问题 或者是需要和开发组人员交流，可以通过 [EasyReact Team](mailto:it_easyreact@meituan.com) 邮箱联系我们。

## 目录

<!-- TOC -->

- [为 EasyReact 贡献代码](#为-easyreact-贡献代码)
    - [快速入手](#快速入手)
    - [创建 Pull Requests](#创建-pull-requests)
    - [提问](#提问)
    - [报告 Issues](#报告-issues)
        - [参考信息](#参考信息)

<!-- /TOC -->

## 快速入手


为了给 EasyReact 贡献代码，你应该打开一个终端

1. 首先再 fork 本项目 然后 clone 到本地的工作目录。

   `$ git clone https://github.com/YOUR_GITHUB_ID/EasyReact`


2. 通常一次 Pull Request 是为了解决一个 ISSUE， 已有的 ISSUE 列表可以在这里找到[ISSUE](https://github.com/meituan/EasyReact/issues)。

   如果没有相关联的 ISSUE， 可以向开发组的人员发邮件[EasyReact Team](mailto:it_easyreact@meituan.com)，我们将会与你讨论这次贡献。

3. EasyReact 项目使用 Apache License 2.0 协议发布. 因此每个文件头部信息必须带上相关协议版权信息。对于一个新文件可以通过一下链接 [License](../common/Copyright.txt) 找到这个模板，将其复制在新文件的顶部即可。

4. 创建新的 PR 前应该保证所有的测试用例是通过的，并且测试用例的覆盖度要大于之前的。如果你对项目添加了新的功能，相应的也需要补充对于的测试用例。
 如果你对书写测试用例有疑问， 可以通过邮件与开发人员联系[EasyReact Team](mailto:it_easyreact@meituan.com)。

5. Git 想要的提交信息要遵守如下模板[commit message templates](../common/commentformat.txt)。

6. 如果以上步骤都满足，可以创建你的 PR 了。


## 创建 Pull Requests

**注意:** 创建 PR 前一定要确保所有的测试用例通过。

EasyReact 使用 [持续集成](https://en.wikipedia.org/wiki/Continuous_integration). 因此你可能在你的 PR 中看到 [Travis CI](https://travis-ci.com/) 相关的评论. Travis is 是一个外部工具，我们使用这个工具检查每个 PR 然后测试对应的测试用例，如果测试用例失败了 这个 PR 不能合入到 master 分支。使用 Travis CI 工具可以确保每次提交代码的稳定性。

当你创建一个PR时，请检查如下要求

1. 请在本地做相关的 diff 确保无关的代码风格没有发生改变，如果你认为代码风格有问题，创建一个单独的 PR 来修改这个问题。
2. 提交代码前使用 `git diff --check` 命令检查下是否有多余的空白字符和换行。

## 提问

如果你又其他访问的疑惑或者需要和开发人员沟通, 可以给我们发邮件 [EasyReact Team](mailto:it_easyreact@meituan.com).。

## 报告 Issues

如果有 ISSUE 需要提出，请遵守此 [模板](../../.github/ISSUE_TEMPLATE/issue-template.md)。

---

### 参考信息

* [GitHub 帮助页面](https://help.github.com)
* [如何创建一个拉取请求](https://help.github.com/articles/creating-a-pull-request/)