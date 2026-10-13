# 数字边界与词法诊断验收

2026-10-05，实现提交 `296ad2dfba92c22dac2945da53fe2748a084e658`。
Go v0.21.0 固定提交 `67968688d9952f50662e979fab1bef889d0d3e57`。
提交后的参考运行均在干净工作区完成。**lint/词法差分 281/282，整体对齐未完成。**

## 实现

- 数字扫描按照整数、小数、指数和指数符号阶段消费字符。前导零后结束 token，
  第二个小数点或指数符号留给后续 token/解析器；不再把 `01`、`1.2.3`、
  `1e2e3` 整体交给 JSON 数字解析器。
- 缺失小数/指数数字时，在首个不合法字符或 EOF 处报错，采用 Go 的分类消息。
  字符按 Go ASCII rune 引用规则显示，包括控制字符、BMP、补充平面及 EOF。
- 未闭合注释、普通/verbatim 字符串、错误 verbatim 开头和文本块诊断采用
  参考措辞及开头位置；非标点、运算符或 ASCII 标识符字符直接由词法器拒绝。
- 两侧 lint probe 输出诊断开始行列。runner 对带 `locations` 的用例同时
  比较冻结位置数组、两侧消息和 found 状态；报告单独记录位置检查计数。
  未为原有 220 项消息用例宣称位置等价。
- 新增 2 项公共 API 回归测试；无公开 `.mbti` 变化。规则和许可归属见 NOTICE。

## 差分与限制

新增 62 项 Go 提取的消息/起始行列用例，包含有效数字与注释、数字 token 终止、
小数/指数缺数字、EOF、不同宽度 Unicode、控制字符、非法标点、注释、字符串、
verbatim 和文本块。首轮 **223/282**，包含 58 项新增差异和 1 项原参考崩溃；
原报告保留于 `_build/lint/lexer-before.json`。修复后 **281/282**，
其中 `location_passed=location_total=62`。

唯一失败仍是 `distinct-entry-cross-import` 的 Go 类型图 panic；继续计入失败
和 reference_crashes，runner 退出 1。本批未删除失败、降低比较标准或接受例外。

Go CLI **1112/1130**，失败名称集合与上一批完全相同；旧 Go/C++ 报告保留为
对应目录的 `lexer-before.json`。C++ **98 通过 + 10 声明差异、0 失败**，
上游语言 **303/303**。这些错误输入主要比较失败结果，不证明完整诊断等价。

转义解码错误、解码与后续词法/语法错误的优先顺序、数字溢出阶段、静态/运行时
诊断及结束范围仍待继续对齐。已知 Evaluator 重复失败 ImportAST 的 1 项差异
本批未重跑 Go API，继续按原版本证据保留，不能与 CLI/lint 失败合并省略。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，无公开接口变化 |
| native debug / release | 各 209/209 |
| Go lint API | 281/282；62/62 消息与起始位置检查；source_dirty=false |
| Go CLI / C++ CLI / 上游语言 | 1112/1130；98+10 声明差异且 0 失败；303/303 |
| Go AST API | 57/57，source_dirty=false |
| lint CLI | 两边各 23 项通过 |
| 独立归档消费者 | 22/22 |
| 隔离 ASan | 209 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 57 AST fixture + 23 lint CLI 检查通过 |

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release 主 CLI：`fdd66e3997e4399e005956b5458b6540c20bffec13f5015e95f8c4b39ef7eee0`。
- lint probe：`46b25ab723ccef15e03df1b47b838d4d8f3ab7e6a3d72a2f940cdab19efc10ed`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；参考 checkout 提交和干净状态通过校验。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`，二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/lint/report.json`、`_build/ast/report.json`、
  `_build/go-differential/report.json`、`_build/differential/report.json` 均绑定
  本实现提交和 source_dirty=false；上游语言报告同样绑定本提交。
- lint API：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.28201.f92edef7`。
- lint CLI：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.35925.6a09b1ea`。
- AST：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-ast-.35779.6226cb00`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.27968.9ffc5082`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.28187.45577c4e`。
  已跟踪源码和工具链使用临时副本，exitcode=99，关闭 leak detection；完整 Go
  lint API 使用独立 release 差分，不声称 282 项均在 sanitizer 下运行。

仅本地提交，没有推送或发布。下一阶段继续解码与错误优先顺序、完整诊断和
源码保真/格式化等整体差距。
