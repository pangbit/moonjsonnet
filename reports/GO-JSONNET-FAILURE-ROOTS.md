# 21项失败的根因与入口诊断最小修复

日期：2026-10-09。分析来自绑定干净`daece32`的Linux完整CLI1150、Evaluator21、
lint410报告：分别19、1、1项失败。原18+1+1未获例外批准；不删除输入、不以
参考程序崩溃计通过，也不以仅修改冻结预期消除失败。

## 按真实原因合并

| 根因 | 输入与数量 | 实际证据与分类 |
| --- | --- | --- |
| tailstrict强制默认参数时参数引用的内部查找失败 | `tailstrict`，1 | Go退出1，`lookUpVarOrPanic`报Unknown variable a；本地结果[5,9]。参考内部崩溃，不能据此证明结果等价 |
| YAML空结果未经长度检查即取第0项 | `parse-yaml-empty`，1 | Go builtinParseYAML索引panic；本地受控Runtime错误。参考崩溃 |
| YAML嵌套错误后调用栈的trace状态无效 | `yaml-nested-errors-discarded`，1 | Go newCall报Saving empty traceElement；本地返回已记录序列化结果。参考崩溃，未将丢弃嵌套错误自动接受为规范行为 |
| removeAt直接使用未检查的Go切片边界 | `remove-at-negative-bound`、`remove-at-upper-bound`、`remove-at-empty-bound`，3 | 同一builtinRemoveAt的slice bounds panic；本地受控越界错误。参考崩溃 |
| 内部flatMerge要求无local，而对象去糖含local | `flat-merge-visible-hidden`、`flat-merge-self-bindings`、`flat-merge-drop-assertions`、`flat-merge-lazy-fields`、`flat-merge-additive`、`flat-merge-duplicate`、`flat-merge-force-elements`、`flat-merge-object-locals`，8 | 全部在builtinUglyObjectFlatMerge同一locals前提panic。desugarer对顶层普通对象加入隐藏$绑定；显式local亦触发此前提。参考崩溃 |
| 内部对象操作将extendedObject强制断言为simpleObject | `flat-merge-extended-object`、`object-operations-inheritance`，2 | 分别在flatMerge与objectRemoveKey发生同类Go接口转换panic。本地返回受控错误，不能从reference panic推断完整继承语义一致 |
| objectRemoveKey重建字段时未保留对象local | `object-remove-local-bindings`，1 | Go重建的simpleObject locals为nil，读取字段时报Unknown variable y；本地结果{"b":4}。参考崩溃 |
| 循环JSON输出无限递归 | `output-json-cycle`，1 | Go致命stack overflow、退出2；本地manifest深度Limit、退出1。参考崩溃及资源政策差异，不复制崩溃 |
| 失败AST被作为成功缓存命中 | Evaluator `import-program-failed-parse-retry`，1 | Go第一次Static错误，第二次ImportAST成功返回nil AST；本地两次均Static错误，均只读一次源。可观测API语义差异，参考没有进程崩溃；仍非兼容通过 |
| 入口与导入同名但不同AST造成类型图缺失节点 | lint `distinct-entry-cross-import`，1 | snippets中b为42，importer中b为true；Go类型图placeholder panic、退出2。本地返回number调用诊断；同名身份优先策略不能从Go崩溃推断为完整布尔语义一致 |
| NaN索引跨架构结果及入口显示名 | `nonfinite-nan-conversions`，1 | 两个独立维度：冻结ARM64成功预期与AMD64真实错误不同；同一相对参数下本地显示canonical绝对路径而Go保留调用路径。后者是本轮所选可修产品输出差异 |

以上11组覆盖全部21项；18个CLI参考崩溃合并为前8组，Evaluator是缓存行为
差异，lint是类型图崩溃，NaN同时包含冻结预期问题与真实输出路径问题。
这些分类不改变任何用例的失败状态。原错误审计中的5项与CLI18重叠，不另加。

参考源码已只读核对固定提交的`builtins.go`（flatMerge、removeAt、objectRemoveKey）、
`imports.go:135`（无条件缓存node，即使parse失败）、`internal/program/desugarer.go`
（隐藏$绑定）及linter的roots/type graph流程。不能仅因同样写着panic就合并不同原因。

## NaN同一输入与同一路径的原始证据

UTC04:45:16–04:45:17，仅用既有二进制轻量复现，没有构建参考或跑全量。
固定Go提交`67968688d9952f50662e979fab1bef889d0d3e57`，构建元数据实际确认
Go1.24.0、linux/amd64、vcs.modified=false。双方cwd均为：
`${LOCAL_PATH_021}/source-numeric-daece32`。
双方唯一参数均为`_build/go-differential/nonfinite-nan-conversions.jsonnet`。
读取该文件后核对与冻结source完全相同：

```jsonnet
local inf=std.sum([1e308,1e308]); local nan=std.sum([inf,-inf]); [[1][nan],nan&1,~nan,std.char(nan),'%c'%nan]
```

双方退出1、stdout为空。Go原stderr为（制表与末尾空行以原始文件为准）：

```text
RUNTIME ERROR: Index -9223372036854775808 out of bounds, not within [0, 1)
	_build/go-differential/nonfinite-nan-conversions.jsonnet:1:67-75	thunk from <$>
	Array element 0
	During manifestation

```

本地同位置的文件名为上述cwd拼接该参数得到的绝对路径；消息、范围、帧名、
空stdout与退出码相同。另以双方相同绝对参数调用，完整三项输出一致。
完整原始stdout/stderr、argv/cwd/source、UTC、二进制和输入SHA及Go构建元数据
保存在远端`failure-analysis/nan-evidence.json`及`nan-*.stdout/stderr`。
CLI19、Evaluator1、lint1的完整失败行亦另存，旧完整报告保持不变。

## 已说明范围的最小候选

选中CLI入口错误诊断显示名，未先修改NaN冻结预期。CLI执行仍使用canonical
Source.id；输出前复制Diagnostic的location/context/Source trace范围，将该入口
的canonical位置映射到调用显示名。相对参数按固定Go的filepath.Join清理，绝对
参数保留原拼写。错误消息字符串、Synthetic帧、导入身份、缓存和求值不改。
静态错误的源片段另注册同内容的显示名，保证按新位置仍能找到原始源码。

两项CLI白盒回归覆盖：包含canonical字符串的用户消息保持原样、导入位置与
Synthetic帧不变、原Diagnostic不被修改、无入口映射时输出不变及Syntax源片段。
UTC04:55:35–04:56:23远端检查/测试/构建/info/fmt全部退出0，CLI包7/7；所有
`.mbti`逐文件SHA保持一致。候选源来自干净daece32加明确的3文件覆盖，原副本不改。

后续聚焦回归为62项完整Go stdout/stderr/退出码比较，含原NaN输入、runtime/
static/syntax/Unicode、消息内路径、绝对导入错误、相对导入正常结果、stream/multi、
exec/stdin，以及相对/点组件/绝对/绝对点组件/符号链接调用。另运行一次现有宿主
检查；必要ASan只测CLI包与该62项，不重复315、4095或1323的全量。
本批不声明相对导入诊断或std.trace路径已全面等价；它们仍沿用既有canonical策略。

即使NaN路径修复后的原始三项输出与Go完全相同，旧整体runner仍要求该冻结
用例成功，AMD64仍会失败。不能把新聚焦套件通过替换为原整体通过，也不能
自动接受例外。以上stderr摘录为Markdown显示移除了行末制表符；原始文件字节保留。

## 聚焦回归与源码绑定

| 远端实际执行 | UTC开始–结束 | 结果 |
| --- | --- | --- |
| CLI检查/测试/release构建及info/fmt | 04:55:35–04:56:23 | 全退出0，CLI包7/7；全部`.mbti`哈希不变 |
| 普通入口完整字节比较 | 05:05:22–05:05:24 | 62/62，原NaN相对调用与Go相同；冻结成功条件仍为false |
| 现有宿主集成 | 05:05:24–05:05:36 | 主集97、多输出26、导入20、诊断20、stack20，全部通过 |
| 相关ASan：CLI测试/构建/完整字节 | 05:09:39–05:10:21 | CLI包7/7、完整字节62/62，无ASan错误；泄漏检测按原合同关闭 |
| 最终零警告脚本：普通/ASan | 05:20:34–05:20:37 / 05:20:37–05:20:43 | 各62/62；仅脚本局部变量改名，现有二进制复用 |

ASan420个副本文件与候选逐文件SHA相同，仅按原工具排除README及有意插桩
的moon.pkg。UTC05:14:06确认UID65534无测试进程。Mac没有编译、测试或归档。
随后因脚本局部变量`alias`触发保留词警告，仅改名`link_path`；原警告和62/62
结果单独留存，最终脚本另作普通/ASan聚焦比较。整理驱动首次在覆盖此前SCP
创建的root所有、0644脚本时退出，UID65534无写权限，尚未运行比较；保留
原文件、所有权和权限，新建UID65534副本完成复核。没有chmod/chown或绕过
拒绝；初次退出日志、原因及实际v2驱动均归档。UTC05:21:05再次确认无验收
进程，释放远端测试时段。

测试锚点为干净`daece32104c0a77a43eae1af732f66180f8e390d`加3份明确源码覆盖，
远端候选工作区有修改，不能伪称绑定干净的新提交。本地`cecf9ec`相对该锚点
仅6份文档变化；本轮3份源码与远端fmt后的源码字节一致：

| 文件 | SHA-256 |
| --- | --- |
| cmd/main/main.mbt | c5150433459af1be5eaf8d6aed06ad1a63e2466beaee14e3c3e52de93c324e59 |
| cmd/main/diagnostics.mbt | f8c9a59debe18a8ee1f87c2d7c18663b2fc22789fbd9f2a0e69ade6bcc9ee52d |
| cmd/main/diagnostics_wbtest.mbt | 3dc9ec90839dfdbd30e1cdc2f4cb5e72972bffd05a3ad1bf2e2fe2456d88e208 |
| tools/cli-entry-diagnostics.mbtx | 1c37d8bb553739b795b23695f8a3dd182709417f62e2c2fdd78a47a57fb0d813 |

核心API、标准库、数学实现和冻结tests/不变。未重跑完整1150、315、4095或
1323；历史1131/1150、20/21、409/410仍绑定旧干净提交，不能转移成新提交
的整体验收。原18+1+1和NaN冻结输入仍未接受为例外；本轮只证明所列范围。

归档`entry-diagnostics-evidence.tar.gz`在远端打包、解包后核验79个文件，Mac只
轻量SCP和SHA校验。SHA-256：
`81e0109e934a3dea542370e39268d8ac8fd34252d97f0deb06e8152014c56849`。
Mac目录`${LOCAL_PATH_009}`，包含：

- [实际结果与UTC摘要](${LOCAL_PATH_009}/path-display-evidence/summary.json)
- [NaN同输入/同路径及固定Go元数据](${LOCAL_PATH_009}/path-display-evidence/failure-analysis/nan-evidence.json)
- [固定Go原始相对路径stderr](${LOCAL_PATH_009}/path-display-evidence/failure-analysis/nan-original-relative-fixed-go.stderr)
- [修复后的62项完整原始输出](${LOCAL_PATH_009}/path-display-evidence/entry-report.json)
- [源码覆盖哈希](${LOCAL_PATH_009}/path-display-evidence/final-overlay.sha256)
- [完整证据归档](${LOCAL_PATH_009}/entry-diagnostics-evidence.tar.gz)

## 下一批：入口std.trace

[入口trace有限修复](GO-JSONNET-TRACE-ENTRY.md)按上述11组回传优先顺序后，
选择同类路径显示的正常Go结果：编辑前9项探针4/9，修复后8/9，相对导入
trace仍明确失败。CLI给3种求值输出入口传入仅用于显示的trace sink，原
canonical执行身份不变。LinuxCLI9/9、完整字节68/68及相关ASan9/9、68/68
通过，公开接口及冻结语料不变，没有重复全量或接受原18+1+1例外。
NaN的ARM64冻结成功条件单列为固定AMD64测试基准不适用，原失败仍保留。
当时Evaluator成功nil AST只考虑扩展当前非空Program返回契约，暂停该项；
不以Null表达式冒充nil。相对导入trace为下一明确的产品输出修复目标。

## 相对导入trace及契约分析续批

[续批报告](GO-JSONNET-TRACE-IMPORTS.md)修复普通相对/嵌套/搜索路径导入trace，
普通及ASan各CLI11/11、完整字节116/116、导入宿主20/20，原探针8/9变为9/9。
canonical别名求值次数与原始字节/代码AST来源的两个独立探针仍false，并有旧
e7c973e及候选同输入证据；不接受例外。11类优先顺序同时覆盖正常输出、
Evaluator、lint身份策略和前8类参考崩溃，不以路径修复替代剩余目标。
Evaluator可新增可选结果查询或生命周期明确的适配器以保留现有API；此前
必须先改变原返回契约的判断过窄。本轮仅分析、未改接口或原失败。

## 可选AST入口续批

[可选导入AST报告](GO-JSONNET-IMPORT-AST-OPTIONAL.md)实现新增可选Program查询，
普通/ASan各26测试、13序列37观测通过；原严格program调用的失败直接复核
仍保留，不能改记原21项通过。该报告直接列出11类影响输入和双方行为，并
依据18项原stderr确认前8类全部含堆栈、地址参数及机器绝对源码路径。
这些可能变化的字节不授予行为例外；未为复制崩溃改坏正常结果。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. The privacy rewrite did not rerun the original validation. Any subsequent CI run is separate evidence.
