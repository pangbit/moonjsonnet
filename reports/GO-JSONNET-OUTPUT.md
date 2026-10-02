# JSON、Python、INI 与 XML 输出验收

日期：2026-10-02；macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9，native。
实现提交：`436a7655d8d8da2da0291d99f29ee2ff44f9729d`。

新增 `manifestJsonEx`、`manifestJsonMinified`、`manifestPython`、
`manifestPythonVars`、`manifestIni`、`manifestXmlJsonml`。
标准库注册清单为 149/163，14 个缺失，0 签名差异；注册不代表全部行为等价。

## 实现边界

JSON 原生输出直接遍历惰性值，读取排序后的可见字段。与固定 Go 参考一致，
没有可见字段的对象不触发对象断言；可见字段仍检查断言。`manifestJson` 复用该
路径，修复旧的先完整显现对象再格式化所引入的求值差异。输出继续受深度、步骤和
UTF-8 字节预算约束。

`manifestJsonEx` 支持任意缩进、换行和键值分隔符，后两者默认分别为换行和
`: `。必需参数按名字检查，所有提供的参数均求值。空容器保留两个周围换行。
数字使用最短可往返固定小数表示，保留负零和非有限值。字符串保留 HTML 字符及
C1，转义 C0 和 U+2028/U+2029；与标准库源码 `escapeStringJson` 的规则不同。

其余五个函数启用固定 Go 标准库源码，由 MoonBit 求值器执行。Python 使用
True/False/None 和既有数值字符串转换；变量输出按字段排序逐行赋值。INI 的
main 可选、sections 必需，数组重复输出键。XML JSONML 保留参考的原始文本和
属性输出行为，不自动转义，始终使用成对标签。

## 验证

| 检查 | 结果 |
| --- | --- |
| debug / release | 各 77/77 |
| Go 完整差分 | 584 项：580 通过，4 项参考崩溃差异 |
| 本轮新增 Go 输入 | 35 项：34 通过，1 项循环对象栈溢出差异 |
| C++ 共享语料 | 98 通过，10 项既有声明差异，无新增失败 |
| 精选上游语言/格式语料 | 303/303 |
| 隔离 ASan | 77 项测试、27 项宿主/CLI 集成通过；泄漏检测关闭 |
| 实际归档独立消费者 | 3/3，新增 JSON、Python 和 XML 调用 |
| 全量标准库清单 | 149/163 注册，14 缺失，0 签名差异 |

Go/C++ 差分、上游语料及反射绑定上述干净实现提交。零警告检查、格式检查、
文档生成和 release 构建通过，公开生成接口没有变化。
最终 CLI SHA-256：
`8faf70d8815b8c64f56f193e37bf2c5a75ad30fc5fbc2f3d52f167457fab4582`。

新增 `std.manifestJsonMinified({x:self})` 在固定 Go 二进制中发生
`fatal error: stack overflow`（退出 2）；本项目返回深度 `Limit`（退出 1）。
该输入没有删除，也没有放宽为预期错误通过。加上既有 `tailstrict` 默认参数及
`objectRemoveKey` 两项崩溃，Go 差分保留 4 项失败并继续返回非零。

整体功能对齐尚未完成；YAML、TOML、其余摘要、宿主/CLI 和工具等缺口见
[整体计划](../docs/GO-PARITY.md)。仅本地提交，未推送或发布。
