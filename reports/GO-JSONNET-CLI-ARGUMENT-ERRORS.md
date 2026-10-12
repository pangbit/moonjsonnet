# CLI 参数错误渲染验收及剩余分支定位

日期：2026-10-08；实现 `1faad8294f66bd41dc567986677582ecae321bff`；
唯一旧本地预期补修 `9c65e8a15ac09f76cc78fbdcb8521bf2318c636d`。
范围依 [有限清单](GO-JSONNET-REMAINING-SCOPE.md)。没有安装、推送或发布。

原未知选项、缺少选项值、空路径选项、错误文件绑定、环境变量、整数和输入数量
错误通过 fail 输出 MoonBit Failure 与实现源码位置。现在由专用 CliError 渲染固定
Go 的消息和换行；未知选项先于取下一个值检查。无输入打印相同错误前缀及本项目
原有帮助。帮助正文前后完整字节相同，SHA-256
`086f09ea1cd64a912e848d9078036ee5a1bb118d60207a67370efdc21775c5b9`。
整数仍保留原正/非负要求及宽整数效果，宿主附加选项、路径、UTF-8、预算合同未改。
根公开接口未变；可执行包的生成接口增加内部 CliError 类型。

新 tools/cli-argument-diagnostics.mbtx 核实固定参考提交、干净状态及Go1.24构建信息。
65项完整 stdout/stderr/退出码对照涵盖未知短/长选项、20种缺值入口、6种空路径
选项、4种文件绑定、4种缺失环境、22种整数语法/溢出、4种数值下限和2种多输入。
另2项无输入检查只验证共同错误前缀和本地既有品牌帮助，完整两边输出保留，
不计完整字节兼容通过。首次新检查抓到多一个LF，已改用现有原始stderr写入。

整体runner首次多出一项旧本地预期失败，但两边实际输出已相同。仅刷新
multi-empty-directory-option 的 moonjsonnet_cli_error；45项输入、Go预期、stdout
和文件结果逐项核对未改，不删除失败。完整回归随后绑定干净9c65e8a：

| 实际 macOS arm64 验证 | 结果 |
| --- | --- |
| 双模式 native check --deny-warn、release build、info/fmt/fmt --check、doc、diff --check | 通过 |
| 普通 / release native | 各302/302 |
| 参数字节 / 品牌帮助 / TTY | 65/65；另2项；25/25 |
| 实际Go API / 捕获CLI字节 | 1323/1323、4095/4095；Go错误1288、3990 |
| 整体 CLI / Evaluator / lint | 1132/1150、20/21、409/410；原18+1+1失败保留 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI / archive / 三个原示例 | 255/255加4branding；两二进制各23；29/29；全部实际执行通过 |
| 上游语言 / 反射 | 303/303；163/163注册；注册不证明行为对齐 |

十三份Go报告和成员报告记录同一提交及source_dirty=false；旧上游语言runner
无dirty字段，保存前后另核查工作区干净。十五份完整副本和manifest：
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.86963.ca41606d`。

| 证据 | SHA-256 |
| --- | --- |
| manifest.json | 547c59aeee03df268c5d8a9498a16db7ce0e0e855f3ebcd67fc18f684ff5d586 |
| 参数完整报告14.json | c8f1b0c997beede0e0ebf5584abe988805dc6be2a3e7f76e8d13646983d24860 |
| CLI字节报告0.json | 201dddabd1ca5c26f86d56a7754f400c124186d900508d62707e744ac5fe4c76 |
| API完整报告1.json | 3eb1855523003f94b369e43ed98db047140a5c15c6a9a62ecb85399c8c636cd4 |
| 整体CLI报告4.json | f0e9590d03c21c93f0b474a0a181058ac8be92a420200b1a15390947a15c0ff3 |
| CLI release | 3cb44edfada7de608baa59436a4d8dc23c23ce2961042d8d43557fa31555eeb5 |
| multi完整语料 | 12be6d4b3210f530a979ab860657ed37a976c10d3fbb7dbe1e17bc2a8309d77f |

包含新65项的完整ASan启动于干净1faad82，实际退出0。native302、宿主97、
multi26、导入/诊断/独立栈各20、实际Go CLI4095、TTY25、参数错误65及帮助2、
依赖33+13、Program参数30、冻结Evaluator21、AST173、lint CLI23、格式化宿主、
节点56、调试器26、API1323全部通过。29个关键实现、诊断输入和工具哈希与副本
相同；9c65e8a仅刷新不在ASan输入中的旧multi消息预期，未更改执行代码。
副本 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.36624.9008bc1c`；
完整日志 `${LOCAL_PATH_002}`，SHA-256
`4df0bfd7e602e263d3c0aeec4747fe7141441b0beac8faae618336702bb90d19`。
哈希核对日志 `${LOCAL_PATH_001}`，SHA-256
`491416914926ddf81550032b6c5a01eca74e54b970ea2cb7765b7c671426fbe8`。
按原合同禁用泄漏检测，安装运行时未改；冻结Evaluator21不代替实际Go20/21。

一次辅助只读ps查询被sandbox拒绝为operation not permitted，未扩大权限重试；
验收依据已完成命令终态与完整日志，不存在未确认的回归终态。

同时将后续标准库分支审计收敛到现有char/codepoint。六项实际对照1/6通过，
四项错误消息不同：char(-1)、char(1114112)、codepoint('')、codepoint('ab')；
char(55296)本地拒绝代理项，Go输出替代字符。char(65.5)两边均截断为A。
这五项是新定位的未修复差异，独立于旧整体18+1+1，不归类为兼容例外。
原始输出：
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-native-string-error-probe-.91393.c31b36f1/report.json`。

固定Go的BreakpointLocations通过SnippetToAST遍历已降级/分析的树，下一有限
核验应比较括号、assert、推导式、slice的枚举及实际停点，不把RawAst词法节点
直接当公开断点。当前26项未覆盖这一范围。输入/输出I/O消息、其余现有原生错误
分支、Linux和原参考例外仍待继续，整体目标未标记完成。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. The privacy rewrite did not rerun the original validation. Any subsequent CI run is separate evidence.
