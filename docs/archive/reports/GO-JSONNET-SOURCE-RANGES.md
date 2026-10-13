# AST 源码范围验收

2026-10-05，实现提交 `3d5991f6ca9f5b59d8ec40b97d02185246bfd876`。
参考 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后的参考差分均在干净工作区完成。**AST 对照 57/57，整体对齐未完成。**

## 实现与接口

- 词法器保存 token 排他结束位置，列号由 Unicode 码点改为一基 UTF-8 字节列号；
  覆盖二、三、四字节字符、注释、文本块、换行和 CRLF。
- 公开 `Ast.end: Location?`、`Ast::source_range` 和 `SourceRange::format`。
  解析节点保留范围，克隆、Program 导出/导入和入口文件名覆盖均保留坐标。
  手工记录必须填写 `end`，合成节点可用 `None`；记录更新仍自动保留元数据。
- 范围遵循 Go 的语义树边界：括号不属于内部节点；调用不包含 `tailstrict`；
  隐式 null、标识符和点号字段键、方法及断言包装节点没有范围。
  解析器另存去糖之前的表达式结束位置，正确处理括号及嵌套 `tailstrict`。
- `from_ast` 拒绝反向、非正数和跨文件范围；调用方显式编辑的合法范围会保留，
  修改语义节点不会自动重算原始坐标。新接口和字段由 `moon info` 生成。

本批只提供节点坐标。完整源码、注释/排版、数字原文、声明/参数范围、Go 的
自由变量元数据、完整诊断结束范围与格式化器仍待实现；不能据此声称源码保真。
源码规则与许可归属见 NOTICE。

## 差分方法与失败保留

在原 20 个 AST 编辑/求值用例上加入 37 个范围用例，预期值从固定 Go 的
`SnippetToAST`、`ast.Clone` 与 `LocationRange` 提取。本地对应解析、克隆及
`Program::from_ast` 往返，逐项比较开始/结束行列、范围字符串及无范围状态。
适配器只选取两种 AST 能对应的语义路径，不要求整棵去糖树结构相同。

首轮 29 个新增用例结果为 **47/49**：对象方法包装函数及 `tailstrict` 调用范围
各有一项差异，原输入、预期和两侧输出保留在 `_build/ast/ranges-before.json`。
修复后再加入 8 项嵌套 `tailstrict` 用例，最终 **57/57**。

共享解析器回归：Go CLI **1112/1130**，18 个失败名称与本批前完全相同；
lint **219/220**，唯一失败仍为 `distinct-entry-cross-import` 的参考类型图
panic，runner 退出 1。旧报告保留为对应目录的 `ranges-before.json`。
未删除失败、未接受新的兼容例外、未把参考崩溃变成通过。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，公开接口变化符合预期 |
| native debug / release | 各 207/207，含公共 API 文档示例 |
| Go AST API | 57/57，source_dirty=false |
| Go lint API / Go CLI | 219/220；1112/1130，原失败保留 |
| C++ CLI / 上游语言 | 98 通过 + 10 声明差异，0 失败；303/303 |
| 独立归档消费者 | 22/22，包含新公开范围和手工 AST 构造 |
| 隔离 ASan | 207 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 57 AST fixture + 23 lint CLI 检查通过 |

旧 Evaluator 重复失败 ImportAST 的 1 项差异本批未重跑 Go API，继续按原版本
证据单独保留。CLI 和语言 runner 的错误输入主要比较失败结果，范围用例通过
也不证明所有诊断文本/帧等价。

## 提交与构建证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release 主 CLI：`a132c4eab8905ff4bc4e4d4981643a47b98c5819f4bbe96c76de917e779fa04f`。
- AST probe：`d6d49f7475e8e2602d75cb02a8639b6a75297afd456b2ea528810dced1e4fe24`。
- Go AST helper：`72f063eb74070a4e95e36c56eedce3208f6407847475a16477b2770997279eac`。
- AST adapter：`758b546baaef08c083554d37f09f8a7e4f66615bb9a3b8c717f1c260b5ac60f4`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；参考 checkout 提交及干净状态校验通过。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`，二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/ast/report.json`、`_build/lint/report.json`、
  `_build/go-differential/report.json`、`_build/differential/report.json` 均绑定
  本实现提交及 source_dirty=false；上游语言报告同样绑定本提交。
- AST：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-ast-.14278.d47ea12f`。
- lint：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.21001.c7554675`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.15762.e16fc922`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.14176.8d9254f4`。
  使用已跟踪源码和临时工具链副本，exitcode=99、关闭 leak detection。
  220 项 Go lint API 在独立 release 差分运行，不声称全在 sanitizer 下运行。

仅本地提交，没有推送或发布。后续继续完整诊断、源码元数据和格式化等整体差距。
