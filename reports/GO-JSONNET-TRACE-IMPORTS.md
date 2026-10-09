# 相对导入 std.trace 显示名与剩余契约

日期：2026-10-09。本地起点为干净
`e7c973e658afc4a8b4a93818dfec4ad8208714e2`。本轮选择上一批原9项探针中
唯一剩余的相对导入trace差异；没有重复历史格式化补丁、全量验收或安装工具。

## 同输入证据与实现

固定Go v0.21.0提交`67968688d9952f50662e979fab1bef889d0d3e57`，现有二进制
构建元数据为Go1.24.0、linux/amd64、vcs.modified=false。双方使用同一cwd
`${LOCAL_PATH_021}/path-display-final-run`、同一源码与
唯一参数`_build/trace-probe/relative-import.jsonnet`。入口导入
`library.libsonnet`，其内容为`std.trace('imported trace',42)`。两边退出0、
stdout均为`42\n`，修复前stderr为：

```text
Go:    TRACE: _build/trace-probe/library.libsonnet:1 imported trace
Local: TRACE: ${LOCAL_PATH_021}/path-display-final-run/_build/trace-probe/library.libsonnet:1 imported trace
```

本轮CLI保存canonical Source.id到调用显示路径的映射。成功resolve后只读取
FileHost已有attempts，按本地目录及反向jpath优先级确定实际命中的请求；不探测
或重新打开文件。相对路径按词法清理，绝对路径保留拼写；嵌套导入沿用已映射
父目录。trace打印使用该映射，消息内的路径文字、Location、Source.id及
canonical缓存身份保持原值。错误诊断中的导入位置仍使用既有canonical策略。
两项白盒回归使用虚构的已缓存请求，证明不新增I/O、不修改位置，并覆盖搜索
优先级、嵌套目录、绝对点组件、Unicode/换行和消息中的canonical文本。

## 限定验证与未通过探针

| 执行 | UTC开始–结束 | 实际结果 |
| --- | --- | --- |
| 普通fmt/check/test/build/定向工具/import-host/info/fmt | 06:39:16–06:40:12 | CLI11/11、完整stdout/stderr/退出码116/116、导入宿主20/20；全部退出0、零警告、全部.mbti哈希不变 |
| 原9项探针复核 | 06:40:12 | 8/9改善为9/9；相对导入与固定Go原始字节一致 |
| 同源相关ASan | 06:43:03–06:43:53 | CLI11/11、完整字节116/116、导入宿主20/20，无ASan错误；424个副本文件SHA相同 |
| 剩余别名探针及原NaN输入轻量复核 | 06:51:48–06:51:49 | 两个别名探针在旧e7c973e及候选均失败；NaN原始输出与Go相同但冻结成功条件仍false |

116项覆盖18种源码各6种入口拼写及exec/stdin各4种输出模式：相对/嵌套导入、
词法同名缓存、同目录symlink、绝对与点组件、搜索优先级、JSONNET_PATH、
消息原样、Unicode、string/stream/multi。逐项保存argv、stdin、环境、源文件
与库内容、原始stdout/stderr/退出码、二进制和冻结输入SHA。未作路径替换或
输出归一化。泄漏检测沿用原ASan合同关闭。

工具另记录两个明确的`passed=false`并打印FAIL的探针，未计入116项范围：

| 探针 | 固定Go与本地差异 | 后续范围 |
| --- | --- | --- |
| distinct-canonical-aliases | 同一物理文件经alias和normal导入，Go按两个foundAt求值并trace两次；本地canonical缓存只求值/trace一次 | 需要独立审查导入身份与副作用策略，字符串映射无法补齐 |
| raw-alias-first | 先importstr alias再code import normal，Go代码AST的trace来自normal；本地第一份canonical显示映射来自alias | 需要区分原始字节缓存与代码AST来源，不能声称所有导入trace等价 |

同一cwd、同一输入以旧e7c973e和新候选实际二进制分别重放，完整输出均保留。
原始值及退出码一致不代表trace通过；没有自动接受例外。

## Evaluator成功nil AST：分析，不改API

当前公开签名为`Evaluator::import_program(Self, String, String) ->
(Program, String) raise JsonnetError`；Program封装有效AST，不表示nil。当前实现
共享字节缓存，仅将成功解析结果写入parsed_imports，所以两次失败均报Static，
源只读取一次。固定Go的`imports.go:135`在SnippetToAST失败时仍无条件缓存
nil node；第一次返回错误，第二次命中astCache后返回`(nil, foundAt, nil)`。
nil AST不等于有效的Jsonnet Null表达式。

可以保留现有方法及严格语义，新增显式可选结果查询，例如
`import_ast(...) -> (Program?, String) raise JsonnetError`，或提供独立适配器。
兼容查询需区分“未缓存/有效Program/缓存nil”，第一次静态或语法失败记录nil
并抛错，第二次返回None及同一身份；共享原字节读取，不污染普通求值的有效AST
缓存。兼容状态须随set_importer及相关reset清理，遵守忙状态保护与字节/深度
政策，不把Limit、读取或宿主故障改成成功nil。适配器还需明确与Evaluator的
重置生命周期绑定。

因此，上一批“必须先决定扩展现有非空返回契约”的判断过窄：新增查询不必
破坏API，也不天然要求再向用户请求实现许可。只有坚持原非空方法本身返回nil
才需要改变契约；将新增入口用于原Go ImportAST验收也需明确接口映射范围。
本轮授权仅分析，未实现该能力、未改签名或冻结Evaluator21项，原失败仍保留。

## 11类根因的可审阅优先顺序

原21项仍按[根因报告](GO-JSONNET-FAILURE-ROOTS.md)合并为11类，数量未变：

| 根因及原输入数 | 优先顺序与结束依据 |
| --- | --- |
| 入口/导入显示及NaN架构冻结，1 | 正常Go输出可直接验证，入口诊断、入口trace、本轮普通导入trace已分批修复；别名身份/来源另保留，NaN冻结成功在AMD64不适用仍失败 |
| 失败AST缓存成功nil，1 | 下一语义候选：优先新增可选查询，保留现有API；须测试首次/重试、有效AST及reset，当前仅分析 |
| lint同名入口/导入身份碰撞，1 | 再定位identity与类型图策略；Go panic不证明本地number诊断语义等价 |
| tailstrict默认参数查找，1 | 固定Go内部panic；先确定正常结果目标，保留失败 |
| 空YAML索引，1 | 固定Go索引panic；受控错误不能自动算兼容通过 |
| YAML嵌套错误trace状态，1 | 固定Go调用栈panic；需确定错误传播目标 |
| removeAt切片边界，3 | 固定Go边界panic；本地受控错误保留差异 |
| flatMerge对象locals前提，8 | 同一内部locals前提；先确定包含隐藏$及显式local的有效目标 |
| extendedObject强制simpleObject，2 | flatMerge/objectRemoveKey接口转换panic；需继承语义目标 |
| objectRemoveKey丢local，1 | 固定Go未知变量内部panic；本地有值不能凭panic证明等价 |
| 循环JSON输出，1 | Go致命stack overflow与本地Limit；明确资源政策，不复制崩溃 |

后8类共18个CLI参考崩溃。原错误审计5项与这18项重叠，不另计。原18+1+1
未获例外接受，NaN冻结success仍false。旧整体1131/1150、Evaluator20/21、
lint409/410只属于此前干净daece32；本轮未重跑或转移这些整体数字。

## 源码、执行环境与证据绑定

所有产品检查均在已授权Ubuntu24.04 x86_64临时目录、UID65534、CPU0/1、
nice10、GOMAXPROCS2、native jobs2下执行，复用现有隔离工具链，无新安装。
远端候选Git head仍为daece32且有覆盖；先核对上一批4份产品哈希证明基线等于
e7c973e，再核对本轮4份覆盖和所有未改文件。ASan排除README及有意插桩的
moon.pkg，其余424文件SHA一致。本地4份覆盖与远端最终fmt后的源码逐字节相同。
不能声称在干净最终提交上重跑整体套件。Mac仅编辑、SCP、SHA校验和本地提交，
没有编译、测试或归档，本任务未启动索引；未推送、部署或发布。

整理脚本首次因显式Json Number模式未忽略repr，被deny-warn在执行前拦下。
v2仅改为数字JSON模式；首次脚本/错误日志和实际v2均归档，没有产品改动或
重复产品回归。本轮无权限拒绝。UTC06:55:32最终确认UID65534无验证或整理进程。

远端打包并解包核验94个文件及manifest，本地manifest复核退出0。归档
`import-trace-evidence.tar.gz` SHA-256：
`168c0ad85e2edfee29f802d4f8b864a59c7c2509cfc099ba691ee0d653b791bd`。

- [实际结果与UTC](${LOCAL_PATH_014}/import-trace-evidence/summary.json)
- [116项原始字节及2项失败探针](${LOCAL_PATH_014}/import-trace-evidence/import-trace-report.json)
- [别名探针修复前后原始输出](${LOCAL_PATH_014}/import-trace-evidence/remaining-collisions-before-after.json)
- [原9项同输入复核](${LOCAL_PATH_014}/import-trace-evidence/original-probe-now.json)
- [原NaN冻结失败](${LOCAL_PATH_014}/import-trace-evidence/nan-frozen-status.json)
- [源码覆盖SHA](${LOCAL_PATH_014}/import-trace-evidence/formatted-source.sha256)
- [完整归档](${LOCAL_PATH_014}/import-trace-evidence.tar.gz)
- [本地提交绑定侧车](${LOCAL_PATH_014}/local-commit-binding.json)

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
