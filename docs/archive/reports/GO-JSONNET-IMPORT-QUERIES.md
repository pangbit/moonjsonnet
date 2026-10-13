# 导入查询与共享依赖扫描验收

2026-10-05，在实现提交 `ff661c4782fb60e8b39e122e0e0393cb5b4e3ead` 的干净工作区
执行参考与集成验收。固定 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。**整体功能对齐未完成。**

## 实现与边界

- Evaluator 新增 `resolve_import`、`import_data`、`import_program` 和
  `find_dependencies`。分别返回身份、原始字节、已验证 Program/身份和静态依赖。
  查询不执行 Jsonnet、不应用 ext/TLA、不调用 native/trace，也不创建运行时状态。
- 查询和执行共享源码/AST；ext/native 变更保留它们，替换 importer 清全部缓存。
  返回的 Program 可独立重新执行；表达式内 import 仍使用既有导入值缓存。
- 二进制回调为所有导入形式提供原始数据；否则文本回调 UTF-8 编码。
  同时提供两者时二进制回调优先。原始查询保留非法 UTF-8/NUL；代码和字符串
  导入仍严格解码。解析失败只保留源码，不安装无效 AST。
- 查询检查当前源码/导入字节预算；缓存 AST 重新检查深度。扫描复用原遍历实现，
  每次重新累计请求和字节预算，保留对象断言不遍历、raw 身份先到的参考行为。
- 运行时回调仅持有读取器快照，避免通过 Evaluator 自身形成引用计数环。
  同一实例拒绝回调重入。路径身份须稳定；未声明原始回调次数或无限制宿主等价。

## 差分发现

原有 11 组生命周期序列保留，新增 10 组查询/执行交错序列。结果为 **20/21**，
共 88 次观测：62 次求值、26 次查询，其中 10 次本地预期错误。
本地预期全部 21/21 通过。

`import-program-failed-parse-retry` 保留为失败：第一次读取 `missing` 源码时，
两边都报未知变量；第二次 Go 返回 `nil` AST 且无错误，本项目继续返回 Static。
参考 `imports.go` 的 importAST 无条件缓存 SnippetToAST 返回节点，因此失败的
nil 节点也命中后续缓存。没有复制该无效成功，也没有把它计入已接受差异。
此项独立于 CLI 的 18 项历史失败，不混合成解释器通过率。

初次查询验收为 19/21，另一个失败来自测试适配器：ResolveImport 返回普通
importer error，而 Go ErrorFormatter 将普通错误标作 INTERNAL ERROR。
适配器改为直接记录查询的 err.Error()；求值诊断仍使用 ErrorFormatter。
缺文件重试的结果、读取数和恢复过程原本一致。首轮完整证据保留在
`_build/evaluators/query-failures-before.json`，未删除任一输入。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；公开接口新增四个方法 |
| debug / release 测试 | 各 181/181；新增 6 项本地回归及 1 项文档测试 |
| Go Evaluator API 序列 | 20/21；上述 1 项真实差异保留 |
| 本地 Evaluator 序列 | 21/21 |
| Program 参数 API 对照 | 30/30 |
| Go CLI 差分 | 1112/1130；原 18 项失败、0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 183 项通过 |
| 依赖工具 | 33/33 fixture + 13/13 本地 CLI 检查 |
| 独立归档消费者 | 19/19，覆盖四个查询接口 |
| 隔离 ASan | 181 测试 + 183 集成 + 33 依赖 fixture + 13 CLI 检查 + 30 参数 fixture + 21 本地 Evaluator 序列通过 |

所有序列固定值/错误、实际源读取数、native 次数和 trace；适配器的 importer
缓存不可变内容，读取数不等于原始回调次数。保留完整输出，错误片段检查不构成
诊断文本或帧集合等价证明。ASan 使用跟踪源码和隔离工具链，exitcode=99，
关闭 leak detection；无 .git 的隔离副本将 API 报告 Git 元数据记为 null。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- 本地 release CLI：`30899ec942567be7f0c70070a5a47d875c4fc0f1bff3161121155b08b4330902`。
- 本地 release deps：`f47bb70b38e800eec459938ac52ebc44afef3cd411171eca4cad4771b028cf9e`。
- 本地 release Evaluator probe：`d8bb7b74af6636612439f32a8c32d11635f8af8e9509cb71b4056a7a36fd0a55`。
- Go Evaluator adapter：`6b6637716cbda9852cac86a3b16c03501d2e8917681a07e078b10608bdd7e39e`；
  源码：`f6d957608b2247c75e2007bc91a807870fde9e3eef91caafeab5efe67d5fc0ac`。
- Go helper 构建前校验 checkout 提交及干净状态；Go 1.24.0、GOWORK=off、
  GOPROXY=off。helper 模块为 `(devel)`，参考提交来自显式 checkout 校验。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`；CLI：
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/evaluators/report.json`、参数 API、Go/C++ 差分、依赖和标准库表面报告
  均绑定上述实现提交及 source_dirty=false；上游语言报告亦绑定该提交。
- Go API 证据：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-evaluators-.27707.81d49266`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.27295.353deef9`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.27328.a22ca1c7`。

只作本地提交，没有推送或发布。可编辑 AST、调试器/EvalHook、完整诊断配置、
格式化/lint、其余语言与平台差距仍待推进；资源、UTF-8 和根目录政策及 nil AST
行为差异均未作为用户已接受的最终兼容例外。
