# 原生格式化入口与首批规则验收

日期：2026-10-05。实现提交：`a29b225d6ffb6e9f67a67318a4e0307111fd62c7`。
以下参考差分在该提交的干净工作区执行，报告记录 `source_dirty=false`。
**当前格式化差分 114/122，整体对齐未完成。**

## 固定环境与参考

- macOS arm64；Moon `0.1.20260920 (914d7da)`、MoonBit `v0.10.14+7d59c7ec9`。
- Go `1.24.0`；go-jsonnet v0.21.0，提交
  `67968688d9952f50662e979fab1bef889d0d3e57`，参考工作区干净。
- Go CLI SHA-256：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ v0.21.0，提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`，与 Go 分开验收。
- 本地发布版 CLI SHA-256：`e0a3abe6ab9b3edb7547e28c77bb2cb22d2e8be9b7b12979ddc6e3cdb2ded6ad`。
- 格式化探针 SHA-256：`756b5489088101c83cf0846f8150737f0034bbf3f7bb9054b5ab59a7ac1aa66a`。
- Go 格式化探针 SHA-256：`e266569cc32bb7ddc8766dacf49e5a92e684d2c8ef67e900b586dd69bfdc67e4`。
- Go 格式化适配器 SHA-256：`fbce4353eaeed424d9bb061e8d87b5eefdb628fa9a1b6a606e35d1e30c4d5533`。
- 冻结语料 SHA-256：`b3d271acbebc466bc0fefbc581aab6ed1b677f24819a2cc5bc5681a1e0574e8a`。

参考只用于开发验收；原生库不链接或调用 Go/C++ 解释器。

## 实现与可验证边界

新增 `format_source`、`ParsedSource::format`、`FormatOptions` 及字符串/注释风格枚举。
保留源码文档不变，格式化不执行表达式、不解析导入，也不要求自由变量已绑定。
先执行原始解析和源码/深度预算检查，输出阶段限制 UTF-8 字节数和 token/trivia 步数。

本批实现数字原文保留、引号/控制字符转义、注释风格、容器填充、多行展开、
尾逗号、切片冒号、嵌套括号、字段/索引简写及对象相加风格。
对象相加改写使用语义树和源码位置确认操作数，避免仅根据相邻 token 误判优先级。
三个 strip 选项遵循 Go 的优先级；保留注释模式用 `null` 替换表达式。

`sort_imports` 当前仅保留选项位置，**尚未实现排序**，API 文档明确说明。
完整注释归属、局部绑定缩进、更多布局规则、可编辑原始 AST、FormatNode 和
jsonnetfmt CLI 仍未完成。公开选项集合和当前通过比例不代表完整格式化兼容。

冻结语料覆盖 116 个有效输入和 6 个错误输入，包含所有选项、组合 strip 优先级、
Unicode/控制字符、verbatim/块字符串、自由变量、不读取的导入、推导式、形参、
局部函数、注释和表达式优先级。错误语料比较已声明的消息片段，未宣称完整诊断等价。
两个实现均校验冻结输出；本地重新解析全部 116 个成功输出，并与 Go 比较幂等性。

Go 自身的两项非幂等行为单独冻结，未强行归为本地失败或擅自改变预期：

- 转义字段名先保留引号、再规范字符串，第二次格式化才简写为标识符。
- `StripEverything` 在多行布局/尾逗号处理后去掉换行，第二次才移除尾逗号。

本地黑盒测试另对 20 个可求值输入核验格式化前后结果相同，覆盖参数、局部绑定、
对象、断言、推导式、切片、Unicode 和多行语法；并测试预算、不可执行源码及文档隔离。
早期原型为 53/85；扩展语料后的最终结果为 114/122，分母变化不作为修复数量。

## 保留的八项格式化差异

| 输入名称 | 当前差异 |
| --- | --- |
| `multiline-local` | 后续 local 绑定尚未与首个绑定对齐 |
| `sort-imports` | 未对连续的顶层导入排序 |
| `sort-imports-binding` | 未拆分并排序同一 local 的多个导入绑定 |
| `import-shadow` | 未按照 Go 的导入整理规则拆行；重复名字不应重排 |
| `comments-in-index` | 点访问改写后的注释间距/归属不同；Go 丢弃的末尾注释在本地保留 |
| `comments-in-computed-field` | 计算字段简写后的块注释间距不同 |
| `nested-comments` | 数组起始块注释前多一个空格 |
| `strip-comments` | 去掉注释后未保留 Go 的缩进空行 |

这些用例全部保留为失败，未跳过、未声明为已接受差异。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| `moon info`、`fmt`、native `check --deny-warn`、`fmt --check`、`doc`、release build | 通过 |
| native 调试版 / 发布版测试 | 229/229；229/229 |
| 格式化 API 差分 | 114/122；8 项失败保留 |
| AST / 原始源码差分 | 173/173 |
| lint 差分 / 消息和位置子集 | 409/410；190/190 |
| Go CLI 差分 | 1132/1150；18 项既有失败，名称集合未变化 |
| C++ CLI 差分 | 98 通过 + 10 项精确声明差异；0 失败 |
| 上游语言回归 | 303/303 |
| 独立归档消费者 | 23/23，含新增格式化 API 与枚举使用 |
| ASan | 229 项测试、183 项宿主检查、33 项依赖 fixture、13 项依赖 CLI、30 项参数、21 项本地 Evaluator 序列、173 项 AST/原始源码、23 项 lint CLI，全通过 |

ASan 使用隔离工具链、禁用 mimalloc，并关闭 leak detection；目录为
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.44416.38c3fdab`。
新增格式化黑盒测试包含在 229 项测试中；122 项完整 Go 格式化差分使用发布版探针，
未宣称该完整语料在 ASan 下执行。ASan 本地 Evaluator 序列不替代尚有差异的 Go API 验收。

lint 的 `distinct-entry-cross-import` 仍触发固定参考类型图崩溃。
Go CLI 的 tailstrict/YAML/删除/内部对象合并/循环输出等 18 项失败继续保留。
本批未改变这些结果，也未以格式化通过比例替代整体完成标准。

原始证据：`_build/formatter/report.json`、`_build/ast/report.json`、
`_build/lint/report.json`、`_build/go-differential/report.json`、
`_build/differential/report.json`、`_build/upstream-language/report.json`。
格式化探针工作目录：
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-formatter-.43802.347f31f7`。
复现格式化差分：

```sh
moon build --target native --release --deny-warn
moon run tools/formatter-integration.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012}
```

差分命令因保留失败返回非零；完整输入和两端输出写入报告。
本批仅本地实现、验证和提交；未推送、未发布。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
