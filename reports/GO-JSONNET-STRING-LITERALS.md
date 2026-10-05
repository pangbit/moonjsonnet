# 字符串转义与错误顺序验收

2026-10-05，实现提交 `8a8cff6c01ed5de15fb32a0313afaf76b1dfa512`。
固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后的参考差分均在干净工作区完成。**lint/解析 340/341，AST 75/75；整体对齐未完成。**

## 实现

- 词法扫描只保留普通字符串的原始转义文本；解析器消费字符串 token 时验证并
  解码。整份源码的词法错误先于转义错误，但 token 之后的语法错误不一定优先。
  不作为字符串消费的 token（例如错误的局部变量名）仍按 token 原文报告语法错误。
- 实现 Go 的普通转义、四位十六进制转义和 UTF-16 代理项组合。单个代理项缺少
  后续 `\uXXXX` 会报错；完整但不合法的组合如 `\uD800\u0041`、
  `\uDC00\uDC00` 产生 U+FFFD。有效高低代理项对产生对应补充平面字符。
- 区分截断转义、截断 Unicode/代理项、缺少低代理项、十六进制错误及未知转义。
  Go 的解析器将内部错误的源码范围再次放入消息，本地也保留这个范围前缀。
  字符串本身包含 BOM、原始换行、verbatim 文本和导入路径的行为有回归覆盖。
- 不新增公开 AST 类型或接口。最终变化集中在 token/字符串解析入口；来源和
  Apache-2.0 归属见 NOTICE。

## 差分与修正过程

新增 59 项消息/起始行列用例及 18 项 AST 克隆/求值用例，预期由固定 Go API
提取。原 release 基线为 **283/341**（57 项新增诊断失败和 1 项原参考崩溃）、
**71/75**（4 项代理项替换值差异）。原始输出保留在
`_build/lint/strings-before.json` 和 `_build/ast/strings-before.json`。

最初仅依据去糖代码安排解码顺序，得到 **291/341**；进一步对照确认 Go 的
`tokenStringToAst` 已经执行转义验证。该失败尝试保留在
`_build/lint/strings-phase-attempt.json`，解析后遍历方案已撤去。最终 59 项
新增诊断用例全部通过，lint **340/341**，带位置预期的用例 **121/121**；
AST **75/75**，包含 18 项新增字符串解码值。

唯一 lint 失败仍为 `distinct-entry-cross-import` 的 Go 类型图 panic，保留
failed/reference_crashes，runner 退出 1。完整 Go CLI **1112/1130**，18 项
失败名称集合与本批前相同；旧 Go/C++ 报告保存为对应目录的 `strings-before.json`。
未移除失败、降低比较标准或自行接受兼容例外。

Go 的 malformed Unicode 错误使用原字符串前四个字节；若截断 Unicode，
其错误消息可能带无效 UTF-8。这里与 Go JSON 适配器序列化后的替换字符比较，
不据此宣称 Go CLI 原始错误字节完全一致。完整诊断排版、结束范围、数字溢出
阶段、其余静态/运行时诊断及源码保真/格式化仍未完成。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，公开接口无变化 |
| native debug / release | 各 211/211 |
| Go lint / AST API | 340/341（121/121 消息与位置用例）；75/75，均 source_dirty=false |
| Go CLI / C++ CLI / 上游语言 | 1112/1130；98 通过 + 10 声明差异且 0 失败；303/303 |
| lint CLI | 两边各 23 项通过 |
| 独立归档消费者 | 22/22 |
| 隔离 ASan | 211 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 75 AST fixture + 23 lint CLI 检查通过 |

旧 Evaluator 重复失败 ImportAST 的 1 项差异没有在本批重跑 Go API，仍依据
原版本证据保留。CLI/语言错误用例主要检查失败结果，不代替完整消息/帧证据。

## 提交与构建证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release 主 CLI：`f7a7e2ec66658020f0d1483b25a8f586f00c53432c3e89c42558ac955374bc20`。
- lint probe：`6f732c067920a5cdc88a1023162c5a62c41e9ba03e573cd1c141a30ad0b09c44`。
- AST probe：`c4ba699ae786ddc1d588d05d198e90b101c1539f4b242fadc0f623cc89372819`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go AST helper：`72f063eb74070a4e95e36c56eedce3208f6407847475a16477b2770997279eac`；
  adapter：`758b546baaef08c083554d37f09f8a7e4f66615bb9a3b8c717f1c260b5ac60f4`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；参考提交与干净状态校验通过。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`，二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- lint/AST/Go CLI/C++ CLI 的 `_build` 报告均绑定本提交及 source_dirty=false；
  上游语言报告同样绑定本提交。
- lint API：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.45306.701949e0`。
- AST：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-ast-.53080.e06a7194`。
- lint CLI：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.54134.bfb878dc`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.45049.94e0a496`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.45889.d25e88d0`。
  跟踪源码与工具链均采用临时副本，exitcode=99、关闭 leak detection。Go lint
  341 项由独立 release 差分覆盖，不声称全部在 sanitizer 下执行。

仅本地提交，没有推送或发布。继续推进其余诊断、完整源码元数据和格式化能力。
