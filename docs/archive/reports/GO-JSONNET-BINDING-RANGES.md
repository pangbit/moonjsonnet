# 局部绑定源码范围验收

2026-10-05，实现提交 `cd99f8cc74dc8e367ee665a77929303ed16436c6`。
固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后的差分均在干净工作区执行。**AST 114/114，lint 381/382；整体对齐未完成。**

## 实现

- `Local`、`Obj`、`ObjectComp` 的绑定由二元组改为 `AstBinding`：名称、
  初始化表达式、可选 `SourceRange`。解析、克隆、Program 转换保留独立声明范围，
  手工构造允许 None，范围形状检查拒绝倒序、非正坐标及跨文件端点。
- lint unused 警告使用声明起点；表达式自身位置保持不变。上一批的
  `local x=1e309;42` 现在报告 `(1,7)`，实际求值该数字仍在 `(1,9)` 报 overflow。
- 遵循 Go 的语法降级区别：`local f(x)=x` 绑定范围为空，unused 位置为 `(0,0)`；
  对象局部函数保留声明范围。函数表达式自身的范围不因此清空。
- 对象计算键在外层作用域解析，不可见同对象局部变量；发现并修正该静态错误的
  消息为 `Unknown variable: x`，位置仍取该引用位置。
- 公开 AST 是 pre-1.0 形状变化；原绑定元组需改成命名字段记录，见 docs/API.md。
  运行时、依赖扫描、类型图及验证遍历同步迁移，未改变绑定求值顺序或惰性。

## 差分过程

新增 20 项 lint 消息/起点、16 项 AST 绑定范围用例，预期由固定 Go API 提取。
覆盖多绑定、遮蔽、多行、Unicode 字节列、对象、推导式、函数、括号、尾调用及
注释边界。旧 release 基线为 **363/382**，证据在 `_build/lint/bindings-before.json`。

第一次实现保留了局部函数范围，得到 lint **379/382**、AST **113/114**。
进一步核验 `desugarLocalBinds` 确认 Go 丢失该绑定范围，并发现计算键静态消息
措辞差异；两者修复后，结果为 **381/382**、**114/114**。中间失败记录保留在
`_build/lint/bindings-range-attempt.json` 与 `_build/ast/bindings-range-attempt.json`。
带冻结位置的用例 **162/162**；未移除用例或放宽比较。

唯一 lint 失败仍为 `distinct-entry-cross-import` 的 Go 类型图 panic，runner
保留 failed/reference_crashes 并退出 1。完整 Go CLI **1112/1130**，18 项失败
名称集合与批次前完全相同；旧 Go/C++ 报告保存在对应目录 bindings-before.json。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；公开接口增加 AstBinding 并迁移三种绑定容器 |
| native debug / release | 各 216/216 |
| Go lint / AST API | 381/382（162/162 消息与起点）；114/114，source_dirty=false |
| Go CLI / C++ CLI / 上游语言 | 1112/1130；98 通过 + 10 声明差异且 0 失败；303/303 |
| lint CLI / 独立归档消费者 | 两边各 23 项；22/22 |
| 隔离 ASan | 216 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 114 AST fixture + 23 lint CLI 检查通过 |

Go Evaluator 的重复失败 ImportAST 差异沿用原 20/21 参考证据，本批未重跑其
Go API 序列。诊断开始坐标相同不证明完整排版/结束范围/帧等价；参数元数据、
源码文本/注释、格式化器、调试能力与跨平台验证仍未完成。

## 构建证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release CLI：`38116f14a9384df13e7099a1b1dd42e75237e951829ced43ce24c54f31e64bf9`。
- AST probe：`dd004af7f74dd3b3106c7df1b943a199103a3c55a4d45f0e003b11d63aceafd8`。
- lint probe：`eed4245f781b42df3e57edeb5d22dd2d56aa00fa198f924521217f13ff95c0a7`。
- Go AST helper：`91f7cb582e0682adc1939828578b1350b845ca1c2b4792e2fd10aef94418ddfd`；
  adapter：`871a2cfd080f90e0d6599731bc3d8782daa7cc80cdfa637b1a2c4039f23f454a`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- helper 使用 Go 1.24.0、GOWORK=off、GOPROXY=off，固定参考提交与干净状态校验通过。
- `_build/{ast,lint,go-differential,differential}/report.json` 绑定本实现提交及
  source_dirty=false；上游语言报告也绑定本提交。
- lint/AST 临时证据：`moonjsonnet-lint-.82900.9aa17ae9`、
  `moonjsonnet-ast-.82418.b494bd04`；消费者 `moonjsonnet-consumer-.83217.9cd8bee2`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.83232.7f10a974`。
  跟踪源码及工具链采用隔离副本，exitcode=99，关闭 leak detection。
  382 项 Go lint API 差分由 release 二进制验证，不声称全部在 sanitizer 下运行。

仅本地提交，没有推送或发布。
