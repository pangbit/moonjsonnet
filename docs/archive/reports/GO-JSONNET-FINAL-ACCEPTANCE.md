# 最终 Linux 验收与明确兼容分类

后续更新：用户给出的Mac最终窗口已完成，[跨平台最终报告](GO-JSONNET-CROSS-PLATFORM-ACCEPTANCE.md)
记录a021c19的ARM64普通/ASan门禁及证据，两平台均按批准标准通过。下文保留
Linux阶段结束时的实际范围和时间，不将后来Mac结果混入Linux执行记录。

2026-10-09。**Linux 在用户批准的兼容标准下验收通过**：普通全量、相关
ASan、精确分类及证据归档均已完成，无新增未批准差异。原始严格比较仍为
失败，不改写成全绿。Mac 按用户要求没有本轮重测，跨平台最终验收尚未闭项。

## 代码及证据绑定

产品修复为 `8e233067f7fb848bb834a0b4ce32ca560e99270c`：CLI 使用词法导入
身份，避免 symlink 别名合并求值，也避免 raw 导入占用代码 AST 的来源。
FileHost 的公开 canonical 缓存与根目录限制未改。此前可选 AST API 实现为
`33d4fb7706f92453d1ed5a949693db99db1da57a`。

| 实际源码状态 | 实际执行或复用范围 |
| --- | --- |
| 干净 `8e23306` | 普通/release check、各330测试、完整release构建、嵌入示例 |
| 干净 `bc1d3c3` | 宿主整组与完整固定Go/上游对照；与8e仅两条本地路径断言及文档不同 |
| 干净 `bf447a9f9001a5e797091ba7663b98bef2a1a163` | 包消费者、doc/info/fmt、相关ASan；与bc1仅消费者测试改用既有set_importer不同 |

上述三个提交的产品 `.mbt`、`.mbti`、C/H、moon.pkg 和 moon.mod 均相同。
所有冻结 tests/ 文件与旧 daece32 基准哈希一致；普通阶段454份跟踪文件在检查
前后字节相同。没有为了统一提交编号重复编译不变的原生输入。
44/44与116/116普通定向证据按用户要求复用：helper字节相同，main只改两行
注释，驱动实际断言该差异；ASan对最终插桩二进制另作对照。

## 普通结果

| 范围 | 实际结果 |
| --- | --- |
| native普通/release | 各330/330，check/build零警告 |
| 宿主主集与子集 | 97；multi26、import20、诊断20、stack20，全通过 |
| 依赖分析 | 固定Go33/33，另13项本地CLI检查通过 |
| 参数 / AST / debugger | 30/30、173/173、43/43 |
| 格式化 / 上游格式化 / 节点编辑 | 736/736、178/178、56/56 |
| jsonnetfmt CLI | 255/255，另4项品牌/帮助检查 |
| 上游语言 | 303/303，无跳过或未支持项 |
| 标准库反射 | 163成员，无缺失或签名差异；反射不等于任意输入行为证明 |
| 诊断 API / CLI完整字节 | 1323/1323、4095/4095 |
| 终端 / 参数错误 / 字符 / I/O / 原生错误 | 25、65、72、45、384，全通过 |
| 入口诊断 / 入口trace | 62/62、68/68 |
| 导入trace / 别名与AST来源 | 116/116，另原探针2/2；44/44 |
| 可选import_ast | 13/13序列、37次观测；原严格调用失败仍保留 |
| 实际安装包独立消费者 | 31/31，含可选AST成功、缓存空值及严格接口继续报错 |
| doc / info / fmt / fmt-check | 全退出0；生成接口没有意外变化 |

普通驱动保留38条阶段记录，其中34条退出0，4条按原严格语料差异退出1：
whole-cli、existing-errors、evaluator、lint。首次失败记录和恢复运行分别保存。
初段原生验证 UTC08:55:04–09:05:28；宿主续跑09:57:35–09:57:41；
实际Go从10:01:00继续，消费者及最终info/fmt于10:07:47完成。
普通阶段的 summary.json 保留当时的 classification_pending=true；它是阶段
快照，后续终态以10:21:04生成的 approved-classification.json 为准。

## ASan 与接口一致性

相关ASan实际执行于10:08:30–10:20:32 UTC，9个阶段全部退出0：原生330/330、
构建、宿主97及26/20/20/20子集、别名44/44、导入trace116/116及原探针2/2、
入口诊断62/62、可选AST13/13及37次观测、API1323/1323、CLI4095/4095。
未出现AddressSanitizer错误或DEADLYSIGNAL；本轮关闭leak detection，不声明
完成泄漏检查。433份插桩副本文件与源文件哈希一致，既有运行时未改。

最终moon info及moon fmt均退出0，454份普通源码检查前后相同。相较eb57730，
公开接口仅增加计划内的 `Evaluator::import_ast(...)->(Program?, String)`；
原 `import_program(...)->(Program, String)` 不变。bf447a9之后仅更新验收文档，
不改产品、测试、接口或构建输入，因此没有为文档提交重复执行重型验收。

## 原始失败与用户批准标准

用户于07:36:48 UTC明确答复“同意”：仅已列明18项CLI及1项lint参考内部
崩溃作为例外；新import_ast提供可选结果，旧import_program严格接口保留；
NaN按同架构固定Go实际输出验收。没有把其他失败纳入该批准。

| 原严格对照 | 原始结果 | 批准的处理方式 |
| --- | --- | --- |
| CLI | 1131/1150，19失败 | 18项已列明Go崩溃；另1项NaN按AMD64真实输出核对 |
| Evaluator | 20/21，1失败 | 原program调用仍失败；新可选接口13/13、37观测对齐 |
| lint | 409/410，1失败 | 仅distinct-entry-cross-import的Go类型图panic |
| 原错误审计 | 290/295，5失败 | 全部与18项CLI崩溃重叠，不增加5项例外 |

18项CLI崩溃的精确输入见[根因表](GO-JSONNET-FAILURE-ROOTS.md)，涵盖
tailstrict、两个YAML输入、3个removeAt越界、8个带locals的flatMerge、
2个extendedObject内部操作、objectRemoveKey局部绑定及循环JSON输出。
完整原始堆栈、机器路径和地址保留。NaN的ARM64冻结成功预期不修改，在AMD64
仍计原始失败；另验相同source/cwd/argv下Go与本地完整stdout/stderr/exit。
精确名单及同架构字节的一致性由单独分类驱动检查，不改写原始报告。

分类驱动于10:21:04 UTC退出0，逐名断言只有18项CLI和1项lint参考崩溃；
原错误审计的5个失败全部重叠，新增例外数为0。可选AST映射及同架构NaN分别
检查，不并入19项崩溃例外。机器报告保留以下两个不同的终态：

```text
raw_strict_comparison_passed=false
linux_acceptance_passed_under_approved_policy=true
unapproved_observed_differences=[]
```

## 首次失败与环境处理

- 两条旧本地断言要求canonical导入路径。原输入分别用固定Go/默认根CLI/
  显式根CLI复核，完整输出一致后才改为词法文件名；输入和其他断言未改。
- 新消费者测试误把resolver传给无参构造函数；改用公开set_importer后31/31。
  没有因测试代码错误修改产品API；原编译日志保留。
- 参数参考适配器最初使用不完整的离线配置。恢复既有gomodcache-download及
  GOSUMDB=off后构建成功；GOPROXY仍off，没有下载或安装。
- 自动审批曾拒绝SCP，担心Git增量含完整私有历史。只读核实69,604字节仅一个
  提交、四份验收文档和一行断言后，同一操作重新获准；未使用间接传输绕过。
- root执行Git读取触发仓库所有权检查；使用原授权所有者UID65534读取，不改
  safe.directory。Git配置路径仅在任务进程指定XDG_CONFIG_HOME，不改系统。

远端为既有Ubuntu AMD64临时目录，UID65534、CPU0–1、nice10、jobs2。
Moon0.1.20260920/moonc0.10.14+7d59c7ec9，Go1.24.0与固定go-jsonnet提交
`67968688d9952f50662e979fab1bef889d0d3e57`；C++固定提交只作语言参考或格式化输入。
没有推送、发布、部署、安装或修改系统服务。

## 证据归档与远端结束

归档程序退出0，324份证据文件加SHA-256清单在远端重新解包并逐项验证通过。
它包含原始报告、首次失败、恢复日志、精确分类、驱动、源码合同、二进制哈希
及实际消费者包。归档为3,295,638字节，本地取回后SHA-256与远端相同：

```text
b9a4316be9365219adc51712a077e6e2eaabeda67fe174a4104179c8acabe0ce
```

- 本地归档：`${LOCAL_PATH_010}/acceptance-8e23306.tar.gz`
- 本地终态：`${LOCAL_PATH_010}/approved-classification.json`
- 本地阶段记录：同目录 summary.json、asan-summary.json、checks.json、files.sha256。
- 远端证据：`${LOCAL_PATH_021}/acceptance-8e23306`。

10:24:48 UTC再次确认UID65534没有残留进程，远端资源已释放。该只读ps查询
因没有匹配进程返回1，不属于验收失败。所有阶段顺序执行，无并发重型任务；
Mac仅做控制、文本修改、Git提交与证据传输/哈希核对，没有本轮编译或测试。

## 尚未闭项

Linux阶段结束时macOS重测尚未执行；后续独立执行已在跨平台最终报告闭项，
没有用Linux结果替代Mac结果。
远端CI、registry发布及部署不在授权范围；本轮没有未解决的权限阻碍。
本报告仅覆盖列明语料、已实现功能和既有宿主策略，不声明任意Jsonnet输入均
无条件等价，也不删除根目录、UTF-8和资源预算合同。

> 隐私脱敏说明：本公开副本以占位符替换具体环境的主机和文件系统标识。未脱敏证据及原始记录的哈希保留在本地。数量和结果描述原始执行；精确诊断和路径字节可能已经脱敏。此次隐私修订没有重新运行原始验收，之后的 CI 运行属于独立证据。
