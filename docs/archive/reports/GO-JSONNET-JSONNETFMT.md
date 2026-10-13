# jsonnetfmt 与原始字节诊断验收

日期：2026-10-08；干净实现提交 `63c6f00a6adfc6668827f37d2a5273ca4c2f6806`。
新增 native `cmd/jsonnetfmt`，覆盖文件/stdin/exec、短选项展开、格式化选项、
多文件原地更新、`--test`、输出文件和目录创建。采用独立 SyntaxLimits，
不执行 Jsonnet 或解析导入。输入保持既有 canonical root、UTF-8 和资源预算政策。

固定 Go v0.21.0 的普通 `-o` 路径总是创建父目录，即使未传 `-c`；本工具保留
该行为。`--test` 首个改变返回 2，清洁输入返回 0，错误返回 1；`-i` 优先于
`--test` 并忽略 `-o`，只更新改变的文件。部分失败保留此前已完成的写回，
格式化失败不打开输出或创建父目录。独立宿主检查验证 unchanged 时间戳、
权限、目录内符号链接与根逃逸、文件/stdin 字节预算、树/递归限制和 UTF-8。

新增 Diagnostic::format_syntax / format_syntax_bytes。完整 token/计算导入
操作数范围由有界源码查询恢复，EOF/词法错误保留点位置。计算导入范围查询
受默认 syntax 预算约束，查询失败回落到开头 token。原 Diagnostic 文本与
context 不变；字节入口保留 Go 的四字节错误上下文及消息自身的换行。
四字节切片可能产生无效 UTF-8，CLI 直接输出原始字节。回归通过文件捕获
stderr 并比较完整字节数组，没有依赖 shell 的有损文本解码来掩盖差异。

| 验证 | 结果 |
| --- | --- |
| check / release build --deny-warn | 通过 |
| native 普通 / release | 各 262/262 |
| info / fmt / fmt --check / doc / diff --check | 通过；公开接口新增两个 syntax 诊断方法 |
| 干净提交固定 Go jsonnetfmt | 255/255；200 个两边预期错误，5 个两边 changed；0 跳过/未支持/声明例外 |
| 版本/帮助独立检查 | 4 项通过，明确本地包与 subset 标识，不计为 Go 文本对齐 |
| jsonnetfmt 宿主边界 | 上述文件/根/预算/UTF-8/副作用检查全部通过 |
| 干净提交格式化回归 | 冻结 736/736、上游 178/178，Go/本地错误均 0 |
| 独立 archive 消费者 | 24/24，包含新诊断方法调用 |
| 隔离 ASan | 262 项 native 和完整既有宿主集成、新 jsonnetfmt 宿主检查通过；leak 检查禁用 |

255 项含 64 项 CLI/文件模式、6 项原冻结格式化错误和 185 项既有 parser、
lexer、字符串解码及重复声明边界；没有删除或修改原 fixture。
固定 Go commit `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0、
GOWORK=off、GOPROXY=off，checkout 干净。格式化 C++ 输入仍固定
`bbb38f1020be1f5aed560928fb839b2c448cefb4`，不提供预期。
macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。

```sh
moon run tools/formatter-cli.mbtx _build/native/release/build/cmd/jsonnetfmt/jsonnetfmt.exe ${LOCAL_PATH_012}
moon run tools/formatter-cli-host.mbtx _build/native/release/build/cmd/jsonnetfmt/jsonnetfmt.exe
```

| 证据 | SHA-256 |
| --- | --- |
| syntax_diagnostic.mbt | `fbc24e9454d5559edafa256789bffd55bdc7830f8596d72641d4a341138a012f` |
| release jsonnetfmt | `a776b564e3558573c5cde813e1d0edb66ff8e237bd32d97ae2ce4095e2d1d4c7` |
| _build/formatter-cli/report.json | `34d7981f4352d3809fce127a5ac1fdf12026ef619066c09f6880094914735368` |
| _build/formatter/report.json | `6aa5cd358d1a72aa1901bb6c0977b13f48bdc9b7068addee2a4a7183e9719e39` |
| _build/upstream-formatter/report.json | `8e23e6bc27688f177919fc54c0e8e87729cc38a99afc10f9f03a5f6d0ddb51af` |

上述三份 Go 报告记录实现提交及 `source_dirty=false`。ASan 副本为
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.62810.9ea05a72`。
旧 CLI 18 项、Go Evaluator AST 缓存及 lint panic 差异仍未获例外确认；本阶段
没有把这些旧失败改为通过。完整 I/O 诊断、运行时帧/config/hook/debugger、
FormatNode 与可编辑原始树、Linux 实测仍待整体核验。没有推送、部署或发布。

> 隐私脱敏说明：本公开副本以占位符替换具体环境的主机和文件系统标识。未脱敏证据及原始记录的哈希保留在本地。数量和结果描述原始执行；精确诊断和路径字节可能已经脱敏。此次隐私修订没有重新运行原始验收，之后的 CI 运行属于独立证据。
