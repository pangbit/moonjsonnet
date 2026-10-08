# 命名诊断帧与可配置渲染验收

日期：2026-10-08；干净实现提交 `d4d42333f8354376c3e2a23ddf02f2ec39591953`。
仅本地提交，未推送、部署或发布。

新增独立 `Diagnostic.trace`，按外层到内层保存源码范围、命名执行上下文和合成
运行时位置。运行时帧在错误展开前快照；缓存断言及 Hook 失败视图各自复制数组，
宿主 before/after 回调异常也保留当前执行范围。既有 `context` 和旧诊断渲染方法
继续兼容原合同；手工构造 Diagnostic 记录现在必须补充 `trace: []`。

新增 DiagnosticFormatter 与 Evaluator 配置/显式渲染方法，提供默认 20 帧、正数
两端裁剪、非正数不限、静态源码片段着色、完整字节输出。字符串输出将非法 UTF-8
替换；字节接口保留固定 Go 在部分 malformed Unicode 错误中截断的原始字节。
源码由宿主按身份提供，清除源码不丢失已保存的静态范围。片段使用 UTF-8 字节列，
保留 CRLF、多行和 EOF；无效范围及超过默认 1 MiB 的源码不展开片段。

解析器另保存对象 assert 的声明范围，不改变公开语义 AST 或节点/深度计数。
Program.assertion_ranges 返回独立映射，编辑语义树后可传回 from_ast；使用到的
元数据验证范围。没有元数据的手工 AST 使用条件/消息范围退化表示。

新固定 Go 公开 ErrorFormatter 适配器检查完整格式化字节、全部有序源/合成帧、
着色调用、成功输出和错误标志。38 项输入分别检查七种 trace 设置，另七项着色，
共 273 项。涵盖函数/默认/惰性参数、闭包别名、对象与局部/方法、断言、加性字段、
数组、递归/tailstrict、导入、ext/TLA、stream/multi、CRLF、多行静态范围和 Unicode。
静态范围读取 Go 错误的公开 Loc()，没有根据本地结果编造预期或规范化诊断文本。

| 验证 | 结果 |
| --- | --- |
| info / fmt / native check --deny-warn / release build / fmt --check / doc / diff --check | 全通过，公开接口变化已核对 |
| native 普通 / release | 各 285/285 |
| 独立 archive 消费者 | 29/29，覆盖新增公开 API 和 README 示例 |
| 干净提交实际 Go 诊断 API | 273/273；Go/本地错误各 266；0 跳过/未支持/声明例外 |
| 干净提交实际 Go 调试器 / AST | 26/26、173/173 |
| 干净提交冻结 / 上游格式化 / 节点编辑 | 736/736、178/178、56/56 |
| 干净提交 jsonnetfmt | 255/255，另 4 项 branding/help |
| 干净提交整体 Go CLI | 1132/1150；483 预期错误，原 18 项失败保留 |
| 干净提交 Evaluator | 20/21；88 观察、62 求值、26 查询，原失败解析缓存差异保留 |
| 干净提交 lint | 409/410；原身份碰撞 panic 保留，CLI 每解释器另 23 检查 |
| 隔离 ASan | native 285/285、完整既有宿主/API、formatter 宿主、节点编辑 56/56、调试器 26/26、新诊断冻结 273/273 全通过；leak 检查禁用 |

上述十份实际 Go 报告均为 source_dirty=false，绑定同一实现提交。固定 Go
`67968688d9952f50662e979fab1bef889d0d3e57`、Go 1.24.0、GOWORK=off、GOPROXY=off；
干净 C++ checkout `bbb38f1020be1f5aed560928fb839b2c448cefb4` 仅提供格式化输入。
实测 macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。

ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.56617.951cd7a8`。
四个下列实现文件与副本 SHA-256 一致；诊断和调试器在副本明确输出 local-report，
Evaluator 本地冻结 21/21 不替代实际 Go 20/21。没有安装新软件或修改已安装运行时。

| 证据 | SHA-256 |
| --- | --- |
| diagnostic_formatter.mbt | `473dab749a0a3c222ec4cdec8624d8c738e8827094ad379b66d78c9ad814723a` |
| diagnostic_trace.mbt | `952f6d3f55db52b19eae78c414e72553bb3198c9d3760d2f7dfa2989afdde06b` |
| eval.mbt | `a19ef7cdb4e130178fb45dadc1aaa3aefa257803c1f086a6f1b0aedfb23776f3` |
| manifest.mbt | `06fb619221a91a3ca5bee1005ddb7089d7389aac7cb7179452f25a3858342b86` |
| tests/go-diagnostic-api.json | `6dbe8f76e790f513c885cbc151e7f34177c462d5cbc9652465a1ef3cf91da7fd` |
| tests/reference/diagnostic.go | `7152c46293d1bb24f04577e46cb944832674ce0904d764297a788d1993c174f7` |
| release diagnostic-probe | `f727db12e7ee37d9fc956a21a40e03d80fb67d8ec85fa55fcd3b0904721692f3` |
| _build/diagnostic-api/report.json | `8a984eccdb97edbddfca4a7582fc093e72511504e30d70061d2fe9ce7b4b6225` |
| _build/debugger/report.json | `0e7a6b1b7a1ea3e3ca0449ddaf21e20e0c64ebc7116446867e7388a01ad5895d` |
| _build/ast/report.json | `5623354be1e6e3f70ed7c350cc2d2c0b5fa2dd27a5b513eba6e90019dde041b6` |
| _build/go-differential/report.json | `a5c84bcc61124d90bcca80f90c06454e90781ef7a575e1576557f5812a7efb0c` |
| _build/evaluators/report.json | `176a5ef198fd1475bc7db3d1f7f2b816247da23d2cb4027294accb6016078666` |
| _build/lint/report.json | `dae479fc3284856dd0264a882889faa6bce7c4c52b515ecedc6a87b4b6247ee9` |
| _build/formatter/report.json | `8adfbd1b03051fbc87ceb404f2f34c7a413f6711619e29971e30ba5252d00c1b` |
| _build/upstream-formatter/report.json | `bea37bd202a60fb0b859fb3d7177a5fc5008014781f1629c73da3dabe430fd09` |
| _build/formatter-node/report.json | `567b52ceab714f5e8cf21640a907055c5498f65ca9265aeee313b0a93487a485` |
| _build/formatter-cli/report.json | `91a0eb2e363d4bcff603be6d42518f23e2e24af9e56250887f5a7ab8469393b0` |

原 CLI 继续使用旧渲染合同，本阶段不声明所有 CLI 错误字节等价，也不声称此有限
语料已覆盖所有标准库/降级语法帧。标准库和更多错误路径、完整 CLI 诊断、Linux
实测及最终整体核验继续推进。18+1+1 项参考差异未被用户接受为例外，全部保留失败。
