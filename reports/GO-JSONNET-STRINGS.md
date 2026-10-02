# 字符串、整数解析与 Unicode 验收

日期：2026-10-02；macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9，native。
实现提交：`76e8cef7582c3ebf6582aaf145fd7563cc6d3005`。

新增 22 个成员：ASCII 大小写转换、Unicode 字符数组、两端字符集合裁剪、空串
判断、Unicode trim/大小写比较、有限次左右拆分、子串查找、整数解析、五种转义、
词法路径拼接及 id。12 个成员采用固定上游 Jsonnet 定义，10 个按 Go 原生覆盖
实现。注册清单为 138/163，仍有 25 个缺失，整体功能对齐未完成。

## 关键边界

- `parseInt` 接受可选正负号，只接受 ASCII 十进制数字；按 Int64 范围检查后
  转为 double，覆盖 MinInt64、MaxInt64、2^53 附近及溢出，拒绝空白、下划线、
  进制前缀和全角数字。`parseHex`/`parseOctal` 保留源码累加语义，不套用 Int64 限制。
- `splitLimit`/`splitLimitR` 要求 -1 或非负 Int32；覆盖重叠分隔符、空输入、
  Unicode 和左右截断。`stripChars` 等原生函数会先强制参数，但字符数组元素
  按成员搜索短路，空串不检查字符集合类型；新增回归覆盖这些与源码定义的差异。
- Unicode 15 White_Space 全集逐项检查，另验证零宽空格和 BOM 不被 trim 删除。
- `equalsIgnoreCase` 采用 Unicode 简单折叠，不做 locale 转换或多字符扩展。
  Kelvin、sigma、微符号、大小写 sharp-S、补充平面字母及土耳其 I 边界均有覆盖。
- 转义覆盖 C0/C1 控制字符、补充平面字符、非字符串输入转换以及 Bash/XML/Dollars。
  `findSubstr` 保留重叠匹配并返回码点位置；`resolvePath` 不归一化路径。

Unicode 数据由固定 Go 1.24.0 `src/unicode/tables.go` 生成，源 SHA-256：
`80a109e5dd4ed40a85d69ddf95175f647bbd68c577d27eb475cda63790bb2487`。
生成器先验证哈希和 Unicode 版本，再生成等价类代表映射及 2,880 组输入对。
Go 与本项目均对全部输入对返回相等；另有非等价、长度不等和多字符负例。
数据来源、BSD 许可和复现方式已记录在 NOTICE、工具及验证文档中。

## 验证

| 检查 | 结果 |
| --- | --- |
| debug / release | 各 71/71 |
| Go 完整差分 | 512 项：509 通过，3 项既有内部崩溃差异 |
| 本轮新增 Go 输入 | 44/44；其中 1 项遍历 2,880 组 Unicode 映射 |
| C++ 共享语料 | 98 通过，10 项既有声明差异，无新增失败 |
| 精选上游语言/格式语料 | 303/303 |
| 隔离 ASan | 71 项测试、27 项宿主/CLI 集成通过；泄漏检测关闭 |
| 实际归档独立消费者 | 3/3；包含 Unicode 表并执行非 ASCII 大小写比较 |
| 全量标准库清单 | 138/163 注册，25 缺失，0 签名差异 |

Go/C++ 差分与反射在上述干净实现提交复跑。零警告检查、格式检查、文档生成与
release 构建通过，生成公开接口无变化。最终 CLI SHA-256：
`bc849a358c6e5061c060fd42c771970e275b5b3bb46e72f71fff0025f68c7910`。

Go 差分继续返回非零，保留 `tailstrict` 默认参数和 `objectRemoveKey` 的两项
上游内部崩溃差异；未将它们计为通过。后续补 UTF-8/Base64、摘要、输出、
宿主/CLI 和工具能力，详见[整体计划](../docs/GO-PARITY.md)。仅本地提交，未推送或发布。
