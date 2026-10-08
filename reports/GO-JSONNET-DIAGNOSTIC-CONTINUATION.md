# 字符、I/O、断点映射与有限标准库诊断验收

日期：2026-10-08。起点为 `a4fce58`；最新实现为
`3d11b458cc1086403b5ac835ff25070a8772bb24`。范围依
[有限剩余清单](GO-JSONNET-REMAINING-SCOPE.md)。仅本地开发、测试和提交；
没有推送、部署、发布、安装或 Linux 容器操作。历史四阶段格式化补丁没有重复应用。

## 修改与回归范围

| 实现提交 | 问题与结果 |
| --- | --- |
| `6971bff` | char 在截断前检查浮点上下界，代理项转换为替代字符；char/codepoint 使用 Go 数值和错误消息。24 个输入经 exec、stdin、绝对文件路径三种入口，完整字节 72/72。 |
| `e95708f` | POSIX I/O 保留真实 errno、操作和错误路径，清理前保存状态；输入、输出、mkdir、多输出及 import 在 CLI 边界使用真实 OS 错误。45/45，包含权限、Unicode、部分输出及路径错误。宿主根目录、UTF-8/NUL、特殊文件和预算政策不变。 |
| `25b3873` | 断点位置采用固定 Go 的降级树遍历顺序，处理括号、assert、数组/对象推导式和 slice；真实 continue/step/finish、变量、断点设置结果均对照。原 26 项逐项保留，增加 17 项，43/43。 |
| `3d11b45` | 对齐现有原生标准库的类型、数值、编码、YAML 和清单输出错误；使用已嵌入标准源码保留真实 format/split/类型谓词调用帧，修复 `%` 降级及点访问的词法诊断上下文。128 个固定输入经三种入口完整字节 384/384。 |

char 的代理项不再作为错误；NaN 转换及正负边界按实际固定 Go 校验。
诊断数值采用 Go 的指数阈值和指数拼写；substr 的固定六位小数由独立 C helper
在临时 C locale 中生成，并恢复原线程 locale。二进制浮点最大有限值、负零、
舍入、NaN 和 Infinity 均有测试。C 缓冲区完整容纳正负最大有限值。

I/O 改动保留 FileHost 的公开错误政策，仅在 CLI 边界区分普通 OS 失败与政策失败。
错误状态由线程局部标量保存并消费，不保存失效指针。MkdirAll 报告真实失败祖先。
共享 Go 引号实现用于 import/lint。仅刷新 14 个旧本地 I/O 消息字段；原输入、Go
预期、成功 stdout 和文件结果逐项核对保留。对应宿主/导入/multi 回归全部通过。

调试器保留标准源码的真实停点，跳过无法导出成公开 AST 的运行时标记及初始化。
普通求值仍使用原推导式执行路径和原预算；仅安装求值 hook 时执行已有降级表达式。
断点收集包含完整有序范围，Go 适配器和本地 probe 均可输出该数据。

标准库先用 34 个当前分支输入实际对照，5/34 通过，修复后 34/34；加上边界输入
得到 69 个输入。再将原整体报告中两边原本均退出 1、源码含 std 的 295 项固定为
明确名字清单，重新以相同绝对输入路径执行两边。修复前 231/295，修复后 290/295。
不是修改或归一化错误输出，也不以注册 163/163 推断行为全部一致。

295 项中的剩余 5 项为 `parse-yaml-empty`、3 个 removeAt 越界和
`object-operations-inheritance` 的参考崩溃；它们属于原 18 项失败，继续保留。
从首次 64 项错误字节差异中，将 59 个非参考崩溃输入另固定为三入口回归；原崩溃
没有从 295 项或整体语料删除。`standard-existing-errors.mbtx` 的 5 项差异仍使
工具退出 1，不自动接受例外。此审计限于固定现有分支和原语料，不枚举任意输入。

YAML 错误保存解析器实际锚点名、标量标签及原整数文字，避免 uint64 经浮点失真；
JSON/TOML 错误路径来自实际递归的字段和数组索引。base64 保留 UTF-8 原始字节偏移，
跳过 CR/LF 时不重排偏移。所有原有独立深度、步骤、输出和栈预算继续保留。

根公开 `.mbti` 没有变化。内部接口新增 POSIX 错误读取、共享引用、数值诊断格式化
及 YAML 锚点名称查询；生成接口差异已核对。

## 同一干净实现的整体证据

| 实际 macOS arm64 验证 | 结果 |
| --- | --- |
| info/fmt、双模式 native check --deny-warn、release build、fmt --check、doc、diff --check | 通过 |
| 普通 / release 原生测试 | 各313/313 |
| 实际 Go API / 捕获 CLI 完整字节 | 1323/1323、4095/4095；错误1288、3990 |
| TTY / 参数错误 / 品牌帮助 / 字符 / I/O / 原生分支 | 25/25、65/65；帮助另2项；72/72、45/45、384/384 |
| 固定原语料标准库错误审计 | 290/295；原5个参考崩溃保留，不计通过 |
| 整体 CLI / Evaluator / lint | 1132/1150、20/21、409/410；原18+1+1失败，无新增差异 |
| 调试器 / AST | 43/43、173/173 |
| 冻结 / 上游 / 节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI / 独立 archive 消费者 / 原示例 | 255/255加4branding；两二进制各23；29/29；全部实际执行通过 |
| 上游 C++ 语言 / 成员反射 | 303/303；163/163注册，注册不证明行为一致 |

参考 Go v0.21.0 固定提交 `67968688d9952f50662e979fab1bef889d0d3e57`，
干净 checkout，Go1.24.0；C++ 固定提交
`bbb38f1020be1f5aed560928fb839b2c448cefb4`。19 份完整报告及源码、语料、二进制
哈希绑定干净 `3d11b45`。上游语言旧 runner 不输出 dirty 字段，保存前后另检查
工作区干净；其余报告明确 source_dirty=false。完整副本及 manifest：
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.74300.e3cb856`。
manifest SHA-256：`a0c1d5fb372c94e6b8a32df6b73b416a12580cdf227f3e219fa51b1434474dea`。

## ASan

包含新增三入口诊断的完整隔离 ASan 实际退出 0。原生313、宿主97、multi26、
导入/诊断/独立栈各20、实际Go CLI字节4095、TTY25、参数错误65及帮助2、字符72、
I/O45、原生诊断384、依赖33+13、Program参数30、冻结Evaluator21、AST173、
lint CLI23、格式化宿主、节点56、冻结调试器43、冻结API1323全部通过。
冻结Evaluator21不代替实际Go20/21；冻结API和调试器另有干净提交的实际Go对照。

副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.42927.eb62763e`。
完整日志：`${LOCAL_PATH_018}`；SHA-256
`62c0f02f9df1e7cfb354ed9f6bf38a683587f6e83a3b538e9bf7f85c22cb85b6`。
全部412个跟踪源码、测试、工具及既有文档与副本逐文件哈希相同；仅排除工具
明确不复制的README和有意加入ASan编译参数的moon.pkg。核对日志：
`${LOCAL_PATH_011}`；SHA-256
`9e9529348ab92899ac3f30743b361501461bc494b779bb8dd59610ef035691fd`。
后续仅更新验收文档，不修改实现或语料。按原合同关闭泄漏检测；安装运行时未改。

## 仍需用户决定的事项

有限清单中的字符、I/O、断点及当前标准库错误分支修复已完成本地验收。
整体目标仍未标记完成：原 18 CLI/标准库参考崩溃、1 个失败解析缓存和 1 个 lint
身份碰撞尚未获得兼容例外确认；Linux native 尚未获得隔离容器和所列安装授权，
其中新增 unzip/perl 也未授权。Linux 的 util-linux TTY 分支未运行，不计通过。
具体方案见 [Linux 隔离验收方案](LINUX-ACCEPTANCE-PLAN.md)。没有执行未授权操作。
远端 CI、推送和发布不在本地授权范围。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
