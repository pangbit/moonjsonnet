# Token 与解析诊断验收

2026-10-05，实现提交 `521019346ff1c4a3c17b10c1b2ae1942160f34c5`。
Go v0.21.0 固定提交 `67968688d9952f50662e979fab1bef889d0d3e57`。
提交后的参考运行均在干净工作区完成。**lint/解析差分 219/220，整体对齐未完成。**

## 实现

- token 在解析期保留原文，错误消息能区分数字原始记法、普通单双引号、verbatim
  引号、文本块和原始转义。使用固定 Go 的 token 名称及消息格式；空字符串只
  显示类别，消息中的 token 内容不按 JSON 再转义。
- 运算符按连续符号扫描，遵循 Go 的末尾一元符号回退规则，并在注释和文本块
  前停止。对象字段直接解析 `: / :: / ::: / +: / +:: / +:::` 运算符；有空格的
  `+ :` 不再误作同一加法字段分隔符。EOF 单独处理，不作为普通运算符。
- 补齐期望标识符/token/operator、缺失逗号/分隔符、参数上下文、多余 token、
  不合法一元/二元运算符及文件末尾诊断。位置参数出现在命名参数之后时，先
  解析该表达式，保留 Go 的错误优先顺序。
- `import/importstr/importbin` 解析完整操作数，再要求其为直接字符串字面量；
  拒绝计算表达式、括号操作数和文本块。不会为计算导入读取文件。
- 新增 2 项公共 API 回归测试。Token 为私有实现，公开 `.mbti` 无变化。

原文只存在于解析期 token，Program/语义 AST 仍不保留完整源码、注释、格式和
结束范围。本批也未对齐全部 lexer/static/runtime 诊断；不以当前消息数组通过
数声称完整诊断等价。源码和控制流参考归属记录于 NOTICE。

## 差分与历史失败

新增 38 项基本错误，最初结果为 **162/202**：新 38 项均失败，加上原有解析措辞
和参考崩溃。该原始结果保留于 `_build/lint/parser-before.json`。随后再加入
18 项运算符、原文字面量、导入和错误优先级边界；全部 56 项最终通过。

最终 **219/220**，上一批 `duplicate-entry-syntax-final` 的措辞差异已修复。
唯一失败 `distinct-entry-cross-import` 是 Go 类型图的
`Bug - placeholder for a dependent node cannot be noType` panic；仍计 failed 和
reference_crashes，runner 退出 1，不复制崩溃、不删除输入、不宽化消息比较。

共享解析器修改后，完整 Go CLI 仍 **1112/1130**，18 项失败名称集合与 fba845d
基线完全相同；旧报告保留在 `_build/go-differential/parser-before.json`。C++
共享语料 **98 通过 + 10 项声明差异，0 失败**；旧报告同样保留。上游语言
语料 **303/303**，0 未支持。CLI 和语言 runner 的普通错误输入主要比较失败结果，
不能当作所有错误文本等价证据；本批文本证据来自 lint runner 的完整消息比较。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，无公开接口变化 |
| native debug / release | 各 204/204 |
| Go lint/解析 API | 219/220，source_dirty=false，1 项参考崩溃保留 |
| Go CLI / C++ CLI / 上游语言 | 1112/1130；98+10 声明差异且 0 失败；303/303 |
| lint CLI | 两边各 23 项通过 |
| 独立归档消费者 | 21/21 |
| 隔离 ASan | 204 测试 + 183 宿主集成 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 20 AST fixture + 23 lint CLI 检查通过 |

旧 Evaluator 重复失败 ImportAST 的 1 项差异没有在本批重跑 Go API，继续依据
其原版本证据单独保留。不得将它与 CLI 18 项或 lint 1 项合并后省略。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release 主 CLI SHA-256：`07944f3e6e375efb5c0af227bc2cf85d32d2811a9423d3de5cd78e0b554a7588`。
- lint CLI：`fe0961865d1e9a75958782c2c6f721e9fdab8f28f8f6fb3e383142df6332f522`。
- lint probe：`2719ab2420a5b841e328a02a9a6f0b7c29ff95e02a3514db78e147361bd69cad`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- Go lint helper：`b7c3c3fd8d4cdac565166b678500417895d192e1ce97e96c3f736a5bdf069333`；
  adapter：`8dcf5c0ddbbff44a80394568f68384a6a756293d2d820d348500b6200ccba41a`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；checkout 提交及干净状态校验通过。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`，二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/lint/report.json`、`_build/go-differential/report.json` 和
  `_build/differential/report.json` 绑定本实现提交和 source_dirty=false；
  `_build/upstream-language/report.json` 同样绑定本提交。
- lint API：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.97265.c245f69b`。
- lint CLI：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.6315.5f31df20`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.97266.84eec0b2`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.97232.60e88fed`。
  跟踪源码和工具链采用临时副本，exitcode=99，关闭 leak detection。220 项 Go
  lint API 由独立 release 差分验证，不声称全部在 sanitizer 下运行。

仅本地提交，没有推送或发布。下一阶段继续源码位置/范围、其余诊断及格式化
等整体差距；参考崩溃也未被自动接受为完成例外。
