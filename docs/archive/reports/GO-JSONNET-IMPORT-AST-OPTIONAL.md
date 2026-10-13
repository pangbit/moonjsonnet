# 可选导入AST查询的限定实现与验收

日期：2026-10-09；本地起点为干净
`eb57730fe975e6f79bbd43fd13dfdebbf2100bbc`。既定
[完成清单](../../development/zh-CN/COMPLETION-CHECKLIST.md)要求参数、导入及正负缓存的API
功能对齐，且明确“MoonBit接口按功能等价，不要求复制Go类型”；
[GO-PARITY完成标准第6项](../../development/zh-CN/GO-PARITY.md)明确保留失败后重复ImportAST
差异。因此本轮是该已有功能的兼容入口，不扩展到新平台、发布或复制参考崩溃。

## 公开合同和实现

新增`Evaluator::import_ast(Self, String, String) -> (Program?, String) raise
JsonnetError`。有效AST返回Some(Program)；该方法第一次遇到Syntax/Static错误
时抛出原错误并按解析后的Source.id记录nil，后续该方法返回None及同一身份。
nil历史独立于只保存有效Expr的parsed_imports，不以Jsonnet Null表达式冒充nil，
不创建运行时状态、不执行native/trace。有效AST和字节仍共享既有缓存。

`import_program -> (Program, String)`签名及语义保持不变，重试仍报静态/语法
错误。它、普通求值和依赖扫描的失败不写入可选查询nil历史；这些严格路径也
不消费nil历史。该隔离是保持原契约的明确边界，不能声明所有Go混合调用的
缓存历史均已等价。set_importer清除nil历史、源码、AST与值；ext/native/TLA/
trace变更及reset不清nil历史。原重入保护和预算保留，缓存nil也重查字节限额。
Import、非法UTF-8、宿主读取和Limit错误不会成为成功nil；有效缓存AST重查深度。
详细API合同见[API文档](../../reference/API.md)。生成接口只有新增方法这一行。

新增7项黑盒、1项白盒和1项文档测试，覆盖首次/重复失败、严格查询交错、
Syntax和Static、有效Null AST、回调惰性、重置恢复、宿主和UTF-8失败、字节及
深度限额、稳定身份别名和重入保护。另复用已有Evaluator/import生命周期测试。

## 固定Go原始行为与适配范围

参考为干净Go v0.21.0提交`67968688d9952f50662e979fab1bef889d0d3e57`。
复用已绑定的Go1.24.0 linux/amd64适配器，SHA
`7c42725eefc1fb13e83697e7ef538bbb223e704745bddc28eefabdfa4abf227a`，
适配器源码SHA
`f6d957608b2247c75e2007bc91a807870fde9e3eef91caafeab5efe67d5fc0ac`。
原报告中的干净checkout/构建绑定及本轮重新核对的checkout状态、版本与哈希
一起归档。没有重新安装Go或依赖。

原冻结`import-program-failed-parse-retry`的源码仍是`missing`，两步均为
`program`，路径main、起点entry。Go首次未知变量错误；第二次结果为
`{"id":"main","nil":true}`、error=false。两次观测都reads=1、native calls=0、
trace=[]。固定`imports.go:135`在SnippetToAST失败时仍缓存nil node，缓存命中
返回node/foundAt/nil error。`importData`每次会调用Importer；适配器reads只计
首次获取内容，其不可变Contents缓存负责让reads保持1。因此本轮不宣称原始
importer调用次数相同，也没有将读取次数与回调次数混淆。

定向工具保留原文件内容、路径和其他步骤，仅在派生的本地请求中将Go
`program`（VM.ImportAST）映射到Moon `ast`（Evaluator.import_ast）。13组37次
观测比较值、id/nil、错误状态、源读取数、native次数和trace序列；错误诊断
比较有无错误，完整文本留存但没有声称逐字节等价。覆盖Syntax/Static重试、
第三次查询、raw/resolve交错、有效AST及Null、求值惰性、ext reset、importer
reset、源修改但不重置、缺文件失败重试及不同身份的独立历史。

随后分别给Go及本地发送**原冻结请求，不改任何步骤**：Go第二次成功nil，
本地严格import_program第二次仍Static，`passed=false`。普通和ASan均核实
这一差距。新增入口可以提供该可选结果能力，但原既定调用尚未关闭；只有
明确采用新增入口作为Go ImportAST的接口映射，才可重新裁决这一功能面。
原tests/go-evaluator.json、known_difference、期望和原21项runner完全不改，
本轮不将历史20/21提升为21/21，也不自动接受兼容例外。

## 实际验证

| 检查 | UTC开始–结束 | 实际结果 |
| --- | --- | --- |
| 普通fmt、零警告check、定向tests、release探针构建 | 07:13:01–07:13:56 | 全退出0，26/26测试 |
| 固定Go可选查询比较、info、fmt | 07:24:07–07:24:09 | 13/13序列、37次观测；原严格调用仍false；接口只新增1行 |
| 同源相关ASan tests、探针构建、Go比较 | 07:25:02–07:26:00 | 26/26、13/13、37次观测；无ASan错误，427份副本文件SHA一致 |

ASan仅排除README和有意插桩的moon.pkg；泄漏检测沿用原合同关闭。Ubuntu24.04
x86_64、UID65534、CPU0/1、nice10、GOMAXPROCS2、native jobs2；复用既有隔离
工具链。UTC07:27:45确认UID65534无验证或整理进程。Mac仅编辑、SCP、哈希
校验及本地提交；没有编译、测试、归档或启动索引。未重跑整体315、1150或
原21序列，不将旧完整结果转移到新提交；未推送、部署或发布。

## 权限与执行失败记录

首次Moon脚本默认target位于root所有的nil-ast-upload目录，UID65534创建失败；
未执行产品检查。保留原权限和日志，使用已授权UID65534临时目录的显式
--target-dir。随后驱动Data.bytes调用、私有辅助函数错误类型及两处测试回调
效应注解在编译时失败，均保留原日志与源码，修正后才执行测试。

产品26测试和探针构建通过后，重新构建Go适配器因默认/root/.cache/go-build
拒绝UID65534而失败。没有改/root权限、提升测试身份或下载依赖，核对历史
二进制与源码哈希后直接复用已验收适配器。定向工具首次因只读Json Null构造
及缺raise编译失败，修正后才比较。执行服务曾返回transport disconnected，
恢复后先读日志/进程，确认命令实际已启动并退出，再继续，避免重复执行。
没有自动审批政策拒绝。本轮全部失败和实际完成日志保留，不伪装首轮通过。

## 11类根因与待裁决范围

现有完整原始失败报告绑定干净daece32，本轮没有重跑18项参考崩溃。只读提取
实际19行CLI失败，确认前8类共18项**全部**含goroutine堆栈、机器绝对源码
路径和地址参数。地址及运行时堆栈含可能变化的内容，不能要求跨运行完整字节
稳定；这些信息不消除值/错误/退出码的差异，也不授予例外。

| 类别/影响输入 | 固定Go行为 | 当前核心行为（原完整报告；本轮未改这些路径） |
| --- | --- | --- |
| tailstrict默认参数查找：tailstrict | Unknown variable a内部panic | 成功[5,9] |
| 空YAML索引：parse-yaml-empty | index out of range panic | 受控Runtime：cannot parse an empty YAML input |
| 嵌套YAML错误trace状态：yaml-nested-errors-discarded | Saving empty traceElement panic | 返回3个YAML字符串，错误字段被省略 |
| removeAt边界：remove-at-negative-bound、remove-at-upper-bound、remove-at-empty-bound | slice bounds panic | 全部受控Runtime：removeAt index out of bounds |
| flatMerge locals前提：flat-merge-visible-hidden、flat-merge-self-bindings、flat-merge-drop-assertions、flat-merge-lazy-fields、flat-merge-additive、flat-merge-duplicate、flat-merge-force-elements、flat-merge-object-locals | Locals should have been desugared统一panic | 前5项成功；后3项分别duplicate field、forced、simple objects without locals受控错误 |
| extendedObject强转：flat-merge-extended-object、object-operations-inheritance | extendedObject→simpleObject接口转换panic | 分别受控flatMerge类型错误、Field does not exist: a |
| objectRemoveKey丢local：object-remove-local-bindings | Unknown variable y内部panic | 成功{"b":4} |
| 循环JSON：output-json-cycle | 致命stack overflow、退出2 | manifest depth Limit、退出1 |
| 失败AST nil缓存：import-program-failed-parse-retry | 首次Static，第二次成功nil；无崩溃堆栈 | 严格方法两次Static；新可选方法首次Static、第二次None；原调用仍失败 |
| lint同名身份：distinct-entry-cross-import | placeholder类型图panic、退出2，也含地址与绝对源码路径 | number调用诊断，不能从Go崩溃推断完整语义等价 |
| NaN架构冻结及显示名：nonfinite-nan-conversions | 固定AMD64索引越界、退出1，无崩溃堆栈 | 上轮路径修复后同输入输出一致；ARM64冻结success条件仍false，绝对调用位置可含绝对路径 |

后续优先审查新可选查询的接口映射范围，再定位lint身份策略。前8类需确定
正常结果或受控错误目标；不为复制Go崩溃破坏已有成功结果。CLI trace另有2个
canonical别名/AST来源探针未通过，详见[上一批](GO-JSONNET-TRACE-IMPORTS.md)。
原18+1+1、NaN冻结失败均未获例外接受，整体状态仍为未完成。

## 源码绑定与证据

远端候选Git head仍daece32且有覆盖；上轮4份源码哈希及原绑定证明产品起点
等于eb57730，本轮6份代码/测试/工具覆盖和生成接口逐文件SHA记录。其他产品
文件/冻结输入不变；本地取回远端最终格式化源码，与实际验证覆盖逐字节相同。
后写文档不是远端干净最终提交的全量测试，提交由侧车单独绑定。

远端打包、解包核验102个文件及manifest，Mac只轻量校验。归档SHA-256：
`53515ecbbe001644239d2b8d1a2f2f51027dab610d9a68014d1947a2530a53bb`。

- 实际结果与UTC（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence/summary.json`）
- 13组原始观测及原严格调用差距（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence/nullable-report.json`）
- ASan结果（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence/asan/nullable-report.json`）
- 11类CLI原始行为及堆栈特征（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence/eleven-root-raw-summary.json`）
- 权限与失败经过（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence/retained-failure-notes.txt`）
- 完整证据归档（仅本地证据：`${LOCAL_PATH_019}/nil-ast-evidence.tar.gz`）
- 本地提交绑定（仅本地证据：`${LOCAL_PATH_019}/local-commit-binding.json`）

> 隐私脱敏说明：本公开副本以占位符替换具体环境的主机和文件系统标识。未脱敏证据及原始记录的哈希保留在本地。数量和结果描述原始执行；精确诊断和路径字节可能已经脱敏。此次隐私修订没有重新运行原始验收，之后的 CI 运行属于独立证据。
