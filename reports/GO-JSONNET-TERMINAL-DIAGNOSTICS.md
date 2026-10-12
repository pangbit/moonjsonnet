# CLI 终端静态诊断着色验收

日期：2026-10-08；实现提交 `679604a98dbf8144fcf7ab4fa5b13cc0eb869180`。
前一阶段四类非尾部重入见 [重入验收](GO-JSONNET-LAZY-REENTRY.md)。
本阶段未安装软件、创建容器、推送或发布。

固定 Go 在 stdout 为终端、TERM 不为 `dumb`、NO_COLOR 为空时，给静态错误的
源码片段添加红色 ANSI 序列。本地原 CLI 未接入已存在的颜色回调。现在使用
现有 POSIX FFI 查询 stdout 的 isatty，按固定参考的条件启用回调；运行时错误
和捕获输出保持原字节。公开根接口未变，只有内部 posix 接口新增终端查询。

新 `tools/diagnostic-terminal.mbtx` 用已有 BSD `script` 创建真实 PTY，比较五种
语法/静态/多行/Unicode/运行时输入在五种环境中的完整 stdout、stderr 与退出码。
包含普通终端、空 TERM、TERM=dumb、非空 NO_COLOR 和非终端捕获；还断言参考
确实输出预期 ANSI 颜色，不裁剪或规范化任何终端字节。25/25 通过。
Linux 分支依据 [util-linux script 官方手册](https://github.com/util-linux/util-linux/blob/v2.41/term-utils/script.1.adoc)
使用 --command/--return/--echo never，并逐参数 shell 引用；该分支尚未实际执行，
不计 Linux 通过。缺少 script 时应报告阻碍，不自行安装。

| 干净实现 `679604a` 的实际 macOS arm64 验证 | 结果 |
| --- | --- |
| 双模式 native check --deny-warn、release build、info/fmt/fmt --check、doc、diff --check | 通过 |
| 普通 / release native | 各 301/301 |
| 新真实终端 / 既有 API / 捕获 CLI 字节 | 25/25、1323/1323、4095/4095 |
| 整体 CLI / Evaluator / lint | 1132/1150、20/21、409/410；原 18+1+1 失败保留 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 编辑节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI | 255/255 加 4 branding；两二进制各 23 检查 |
| archive / 三个原有示例 | 29/29；环境、服务面板、嵌入示例与预期错误实际执行 |
| 上游语言 / 标准库反射 | 303/303；163/163 注册，0 缺失/签名差异；不等于行为通过 |

参考与工具版本沿用重入阶段。十二份 Go 报告及成员报告记录同一提交和
source_dirty=false；旧上游语言 runner 无 dirty 字段，保存前后另核对 Git 干净。
十四份完整副本和 manifest 保存于：
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.14834.1cd54e0b`。

| 证据 | SHA-256 |
| --- | --- |
| manifest.json | 192ba0487ec4fdafc054e7dd15de438f063317f0128606188a1dafd3ec8c01a9 |
| 终端完整报告 13.json | 93a1945e645bd8fe661bb275da59ba98f966a90a5f8a1bee842c73b326b42dc0 |
| 捕获 CLI 字节报告 0.json | 049e47d7a0de6d2f5b522ea3fc3c5e459f8024773290d91c1e4247a84d4a2368 |
| API 完整报告 1.json | bcdf2ba93fa08834446a8e628975717250285671183654f0b54930d46521af3c |
| CLI release | 49ef6107dc68f96fc7e0a7ca234027239508e9928ea3837bddd64636f51061d4 |

ASan 工具已加入 25 个真实终端对照；本次完整运行退出0，native301、宿主97、
multi26、导入/诊断/独立栈各20、实际Go CLI4095、TTY25、依赖33+13、参数30、
冻结Evaluator21、AST173、lint CLI23、格式化宿主/节点56、调试器26、API1323
全部通过。24个关键源码/语料/工具哈希与实际副本相同。
副本 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.91039.c4d5ba2e`；
完整日志 `${LOCAL_PATH_026}`，SHA-256
`924f7656e5b365ea93618a804935699e04174508d367cf9ac8af524b363fdcf8`。
原合同禁用泄漏检测，安装运行时未改；冻结Evaluator21不代替实际Go20/21。

有限剩余范围见 [清单](GO-JSONNET-REMAINING-SCOPE.md)。参数错误审计已复现
本地 Failure 源码位置与 Go 简短 CLI 消息的差异，作为独立下一阶段；输入 I/O、
既有标准库错误分支与原始/降级断点仍需核验。Linux 安装和参考例外尚未获授权。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. The privacy rewrite did not rerun the original validation. Any subsequent CI run is separate evidence.
