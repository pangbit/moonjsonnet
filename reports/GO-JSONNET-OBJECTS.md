# 对象标准库验收

日期：2026-10-02；macOS arm64，native，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
实现提交：`5c19d7dcd9308ffe91d5feb48e72a6a76e6dc8ae`；
原生 equals 参数修复：`28d46cd0518888ccdd41684742b3c85e70bac046`。

新增 12 个成员：`get`、`objectValues`/`objectValuesAll`、
`objectKeysValues`/`objectKeysValuesAll`、`mapWithKey`、`prune`、
`objectFieldsEx`、`objectHasEx`、`objectRemoveKey`、`primitiveEquals`、`equals`。
其中反射、删除和相等性按 Go 原生覆盖实现；其余由 MoonBit 求值器运行固定标准库源码。

原生 `objectRemoveKey` 保留隐藏字段，复制剩余字段并重新绑定 `self`，丢弃对象断言，
不修改输入。`equals` 使用 Go 的 `x/y` 参数名，而不是源码定义的 `a/b`。
本地测试及 31 条新增 Go 输入覆盖命名参数、惰性默认值和字段、隐藏字段、继承、
对象局部绑定、断言、递归 prune、短路相等性及错误类型。

## 验证

- 修复后的 debug/release 各 58/58，零警告检查、格式检查、文档生成、构建通过；公开接口未变。
- `28d46cd` 干净工作区 Go 差分：307 项，303 通过、4 失败、0 未支持、0 跳过。
  新增 31 项中 29 项通过，另 2 项确认是固定参考内部崩溃，保持失败记录。
- 同一干净提交标准库反射：62/163 注册、101 缺失、0 签名差异；注册不证明行为完全一致。
- 独立归档消费者 3/3；包括运行打包标准库。
- `5c19d7d` 上 C++ 共享语料 98 通过、10 项原有参考差异；精选上游语料 303/303。
- `5c19d7d` 隔离 ASan：58 项本地测试及 27 项集成通过，泄漏检测关闭。
  此项不冒充后续 equals 参数修复提交的 ASan 证据。

最终 CLI SHA-256：`0e6d81795e69d1b0c95e4ca91afa1892c85e4fb7d74fa96c2028fceeaa5f9e61`。
参考版本和提交保持与[整体计划](../docs/GO-PARITY.md)一致。

## 保留的 Go 差异

1. `tailstrict`：参考在默认参数引用中内部报 Unknown variable。
2. `bitwise-int64-upper-boundary`：参考允许不可表示的正 `2^63` 整数转换。
3. `object-operations-inheritance`：参考在 `objectRemoveKey` 将 extendedObject
   强制断言为 simpleObject 时崩溃；本项目正常报告被删除的 self 字段不存在。
4. `object-remove-local-bindings`：参考丢失对象局部绑定并内部报 Unknown variable；
   本项目保留绑定并返回正确对象。

这些输入未移除、未算通过，Go 差分命令继续返回非零。最终兼容例外尚未获确认。
整体对齐未完成，后续继续数组、数学、字符串、输出及 CLI/宿主能力。
本批仅本地提交，没有推送、发布或跨平台通过声明。
