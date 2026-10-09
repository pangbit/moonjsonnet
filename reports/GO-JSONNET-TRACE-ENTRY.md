# 入口std.trace显示名的有限修复

日期：2026-10-09；本地起点为干净`6834f4702acd40d72b5e832aa576d6965717a182`。
目标来自[11类失败根因](GO-JSONNET-FAILURE-ROOTS.md)中的调用路径显示维度；
入口错误位置已修复，本批只处理仍输出canonical路径的入口std.trace。
未接受原18CLI+1Evaluator+1lint例外，不修改冻结输入或预期。

## 根因、影响用例与顺序

| 根因 | 影响输入 | 顺序与所需证据/决定 |
| --- | --- | --- |
| tailstrict默认参数内部查找失败 | tailstrict，1 | Go内部崩溃；没有普通成功/受控错误结果可直接作为修复目标，暂停复制崩溃行为 |
| YAML空结果越界 | parse-yaml-empty，1 | 同上，保留失败 |
| YAML嵌套错误后的trace状态无效 | yaml-nested-errors-discarded，1 | 需要先明确嵌套错误传播的兼容目标；保留失败 |
| removeAt切片越界 | remove-at负界/上界/空数组，3 | Go内部崩溃；保留受控错误与未解决差异 |
| flatMerge的locals前提 | visible-hidden/self-bindings/drop-assertions/lazy-fields/additive/duplicate/force-elements/object-locals，8 | Go内部崩溃；保留失败，不把所有对象语义推定等价 |
| extendedObject强制断言 | flat-merge-extended-object、object-operations-inheritance，2 | Go接口转换崩溃；保留失败 |
| objectRemoveKey丢失local | object-remove-local-bindings，1 | Go内部崩溃；保留失败 |
| 循环JSON无限递归 | output-json-cycle，1 | 涉及栈溢出与资源政策，需兼容取舍后才能改，不复制致命崩溃 |
| 失败AST被作为成功nil命中 | import-program-failed-parse-retry，1 | 优先语义项，但当前返回非空Program；需决定是否允许扩展返回类型以表示成功nil，本项暂停 |
| 入口/导入身份碰撞 | distinct-entry-cross-import，1 | Go类型图崩溃；需身份策略证据/决定，仍非通过 |
| 架构冻结预期及路径显示 | nonfinite-nan-conversions，1 | NaN冻结成功条件单列为AMD64基准不适用并保留失败；路径家族的正常Go结果可直接验证，入口trace先修，相对导入trace为下一明确目标 |

具体原用例名、数量和原始失败行仍以根因报告及其归档为准。此排序不授予例外。
Evaluator需要回答的具体问题是：是否要求匹配Go第二次成功返回nil AST，并允许
扩展当前`import_program -> (Program, String)`的非空返回契约；现有API不能用
有效的Null表达式冒充nil AST。未作决定前仍重复报告静态错误，差异继续保留。

## 编辑前的固定Go原始证据

UTC05:28:23–05:28:24，既有二进制9项轻量探针，没有产品/参考构建。
参考Go1.24.0、linux/amd64，提交`67968688d9952f50662e979fab1bef889d0d3e57`、
vcs.modified=false。双方cwd为
`${LOCAL_PATH_021}/path-display-final-run`。
同一个文件`_build/trace-probe/entry.jsonnet`内容为：

```jsonnet
std.trace('entry trace',42)
```

双方参数均为该相对文件，退出0、stdout均为`42\n`；原stderr为：

```text
Go:    TRACE: _build/trace-probe/entry.jsonnet:1 entry trace
Local: TRACE: ${LOCAL_PATH_021}/path-display-final-run/_build/trace-probe/entry.jsonnet:1 entry trace
```

原9项4/9一致：绝对入口、exec、stdin、绝对导入一致；相对/点相对/绝对点组件/
符号链接入口及相对导入有文件名差异。固定Go的builtinTrace打印当前位置的
DiagnosticFileName和line；引用原始输出定义本批显示行为，不改变AST文件身份。
逐项stdout/stderr文件、argv、cwd、源文本、二进制和输入SHA、构建元数据均归档。

## 修改与定向验证

CLI给evaluate_text/evaluate_stream/evaluate_multi显式传入trace sink，打印前
只将canonical入口位置映射到既有调用显示名。相对路径清理，绝对拼写保留，
行号及消息文本保留。导入位置、匿名名称、核心trace API、std.thisFile和
缓存/求值身份均沿用原行为。只涉及3份CLI源码、两项新增白盒回归及新.mbtx工具。

| 远端实际执行 | UTC开始–结束 | 结果 |
| --- | --- | --- |
| fmt/check CLI/test CLI/release build/trace/info/fmt | 05:34:29–05:35:21 | 全退出0，CLI9/9、定向完整字节68/68，零警告；全部.mbti哈希不变 |
| 同一9项原探针 | 普通驱动末段，逐条raw归档 | 8/9；入口新增4项一致，相对导入trace仍失败，不计例外 |
| 相关ASan CLI测试/构建/trace | 05:36:27–05:37:09 | CLI9/9、完整字节68/68，无ASan错误；421副本文件一致 |

68项逐一比较固定Go与CLI的完整stdout/stderr/退出码，无路径归一化；覆盖10种
源×6种文件拼写、exec/stdin各4输出模式：普通JSON、Unicode/多行消息、消息
中的canonical文本、trace顺序/惰性、字符串、stream、multi、trace后错误及绝对
导入。单独的相对导入trace探针仍输出`passed=false`，日志明确FAIL；不能把
68项有限范围成功等同全部trace或整体目标通过。白盒回归证明打印映射不修改
位置/消息及canonical std.thisFile结果。泄漏检测按既有合同关闭，安装运行时不改。

普通与ASan均使用已授权临时工具链，UID65534、CPU0/1、nice10、GOMAXPROCS2、
native jobs2。UTC05:39:30确认无验收进程；Mac没有编译、测试或归档。
两个临时驱动初次启动分别因Json.bool不存在、local保留词在编译阶段退出，
没有执行产品回归；原脚本/错误日志保留，实际执行均来自对应v2驱动。

## 源码绑定与剩余项

远端Git head仍为daece32，工作区有明确覆盖；不能伪称干净的6834f47快照。
上轮3源码与工具哈希先逐一核对，证明产品基线等于6834f47；除本轮3源码及
新工具外的基线文件逐一哈希不变，公开接口与tests/不变。格式化后的精确覆盖为：

| 文件 | SHA-256 |
| --- | --- |
| cmd/main/main.mbt | 3b5bcd0582e42b123c3ef09239653ad4f48954248b6212a759f0c6be5665fb36 |
| cmd/main/diagnostics.mbt | c22263981db0b7ce99d10939114bbe736df92b48e0034fc106d3a748fe374b03 |
| cmd/main/diagnostics_wbtest.mbt | abebd53ab90fa1343c42d59d6889efe7154761e073ed4770aede9143d0965649 |
| tools/cli-entry-trace.mbtx | c4fc4e8ce96ecdc7ffdea3182347a9adb2818578bf84f8ed18ae34f5a502eb5c |

核心API/标准库/数值实现不变，没有重复315、1150、4095、1323等全量验收。
旧1131/1150、20/21、409/410只能用于旧提交，不迁移为本批完整验收。
NaN原ARM64成功条件对固定AMD64参考不适用；UTC05:41:33–05:41:33另验原
source、原相对参数，两边均退出1并完整输出一致，仍保留
`original_frozen_success_condition_passed=false`。
原18+1+1未接受，相对导入trace仍未对齐，Evaluator成功nil的API取舍待决定。

归档摘要、实际命令UTC、raw输出、源码/语料/二进制/运行时哈希及两个初次错误
统一保存；打包/解包核验仅在远端，Mac轻量取回与SHA校验。归档身份及本地
提交绑定以独立侧车记录，不改变原归档。远端解包核对139个文件，Mac取回后
全部哈希再次通过；UTC05:43:58确认无验收进程。归档
`trace-entry-evidence.tar.gz` SHA-256：
`eceab997e8be8dfeef76243994d72c78f942f52eead4fe46a55b3a0c64c66ee7`。
Mac目录`${LOCAL_PATH_027}`，可直接读取：

- [实际结果与各命令UTC](${LOCAL_PATH_027}/trace-evidence/summary.json)
- [修复前9项固定Go原始输出](${LOCAL_PATH_027}/trace-evidence/pre-repair-probe/report.json)
- [修复后原9项输出与剩余失败](${LOCAL_PATH_027}/trace-evidence/post-probe.json)
- [68项完整字节及相对导入失败探针](${LOCAL_PATH_027}/trace-evidence/trace-report.json)
- [NaN原冻结输入的AMD64失败状态](${LOCAL_PATH_027}/trace-evidence/nan-frozen-status.json)
- [完整归档](${LOCAL_PATH_027}/trace-entry-evidence.tar.gz)
- [本地提交与源码覆盖绑定](${LOCAL_PATH_027}/local-commit-binding.json)

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
