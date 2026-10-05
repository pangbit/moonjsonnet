# 数字原文与延迟转换验收

2026-10-05，实现提交 `a0c487154da954971fe358f9cf9f13edc6c44390`。
固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后差分在干净工作区完成。**AST 98/98，lint 360/362；整体对齐未完成。**

## 实现与差分

解析数字使用公开 `AstKind::NumberLiteral(String)`，克隆及 Program 往返保留
`1.20E+003` 等原始拼写。原手工 `Literal(Json::number(...))` 仍可使用。
这是 pre-1.0 AST 形状变化，调用方模式匹配需要处理新增变体，见 docs/API.md。
手工数字节点必须是单个无符号十进制 token；负号仍通过 Unary 表示。

词法阶段仅验证语法，浮点转换推迟到实际求值。`1e309` 可以解析，但求值报告
Runtime overflow；未使用的局部绑定、数组元素、函数参数及未执行分支不会触发
转换。极小指数下溢为零、零尾数及舍入边界有固定参考覆盖。lint 类型图将数字
视为 number，无法转换的常量索引保持未知索引，不提前拒绝程序。

新增 21 项 lint 及 23 项 AST 用例，预期由固定 Go API 提取。旧 release 基线
为 lint **346/362**、AST **80/98**，保存在 `_build/lint/numbers-before.json`
及 `_build/ast/numbers-before.json`。最终 AST **98/98**；lint **360/362**，
消息与开始位置用例 **141/142**，未弱化检查或删除失败输入。

lint 两项失败：原 `distinct-entry-cross-import` 的 Go 类型图 panic；新增
`number-literal-8` 暴露已有声明位置缺失。`local x=1e309;42` 两边都报告
`Unused variable: x`，本项目位置为 `(1,9)`（初始化表达式），Go 为 `(1,7)`
（声明名）。该差异不是兼容例外，下一批应保留声明元数据并修复位置。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；公开接口增加 NumberLiteral |
| native debug / release | 各 213/213 |
| Go lint / AST API | 360/362；98/98，source_dirty=false |
| Go CLI | 1112/1130，18 项失败名称集合与批次前完全相同 |
| C++ CLI / 上游语言 | 98 通过 + 10 声明差异且 0 失败；303/303 |
| lint CLI / 独立归档消费者 | 两边各 23 项；22/22 |
| 隔离 ASan | 213 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 98 AST fixture + 23 lint CLI 检查通过 |

Go CLI 与 lint runner 保留失败并退出 1。旧 Evaluator 重复失败 ImportAST 的
差异沿用原 20/21 Go API 证据，本批 ASan 的本地 21/21 不替代参考验证。
AST runtime 错误片段检查不证明完整错误消息或帧等价。声明/源码元数据、
完整诊断、格式化器、调试能力及跨平台验证仍有缺口。

## 构建与提交证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release CLI SHA-256：`5c7f818212bc25a7ca5165ded8c0df13371ee62f6aff5654c5b4e5a43878c4df`。
- AST probe：`b7cd0741f9efeadf50d92d1eca9828a00de23347554aaaa6c76a772f9205a930`。
- lint probe：`00ddc581aee50ec298b4e13e31b7aeeff2aa0d998b86cdfdf7cd33247fcf4aa9`。
- Go AST helper：`ec4813deb426a420ce3764dba88fca88945df7ae00c25891427a32b4cfe39e9b`；
  adapter：`04ec78182c3620ce66cef34b1bf8173583976747b22fe8a2810fe14447edadf8`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- Go helper 使用 Go 1.24.0、GOWORK=off、GOPROXY=off，校验固定参考干净状态。
- `_build/{ast,lint,go-differential,differential}/report.json` 均绑定上述实现提交和
  source_dirty=false；上游语言报告也绑定该提交。旧 Go/C++ 报告保存为 numbers-before.json。
- ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.62414.c5ea3a0d`。
  跟踪源码及工具链采用隔离副本；exitcode=99，关闭 leak detection。
  完整 Go lint API 差分由 release 二进制验证，不声称全部在 sanitizer 下执行。

仅本地提交，没有推送或发布。
