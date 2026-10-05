# 导入排序与格式化布局验收

日期：2026-10-05。实现提交：`de430a05782acc2bc2afece72103dd91d8858dff`。
格式化参考差分在该提交的干净工作区执行，`source_dirty=false`。
**当前差分 171/177，尚未完成整体格式化或项目功能对齐。**

## 固定参考与证据身份

- macOS arm64；Moon `0.1.20260920`、MoonBit `v0.10.14+7d59c7ec9`。
- go-jsonnet v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`，参考工作区干净；
  适配器使用 Go `1.24.0`、`GOWORK=off`、`GOPROXY=off` 构建。
- 本地格式化探针 SHA-256：`22dbf08ed3279878ee4f8322d560a5e5c20ab994d90f4f855762a4cf3c6d00eb`。
- Go 格式化探针 SHA-256：`e266569cc32bb7ddc8766dacf49e5a92e684d2c8ef67e900b586dd69bfdc67e4`。
- Go 适配器 SHA-256：`fbce4353eaeed424d9bb061e8d87b5eefdb628fa9a1b6a606e35d1e30c4d5533`。
- 冻结语料 SHA-256：`977d80be45b157480cd5c2138cc69615ee86f3a7566e41fd6a43e2ace2644b9a`。
- 导入实现 SHA-256：`7716603ef8d141d685ee349f629f0012d09f5bd80f10710d52c65ad7989e78b6`。

## 实现与修复

`sort_imports` 开始生效。只整理文件开头连续的纯代码导入 local，拆分同一声明中的
多个导入绑定，以规范字符串之前的原始 UTF-8 路径为键排序。使用字节词典序，
避免 MoonBit `Bytes.compare` 的长度优先排序和 UTF-16 字符串顺序造成差异。
空行、段落注释隔开组；相邻行尾注释随导入移动；同组重名变量保持顺序。
普通绑定、括号包裹的导入、`importstr`/`importbin` 和函数内部导入不被重排。
重排后重新建立词法位置，使行尾注释判断对应新的源码顺序。

同时修复 local 首绑定/后续绑定缩进、括号内 local 等号间距，以及字段、索引、
逗号、分号和容器附近块注释的间距。点访问简写跟随固定 Go 实现，会丢弃原右方括号
前的注释；该行为有独立差分输入保留，并非宣称所有注释均无损。
补齐删除注释之前已经由换行规范化插入的独立行尾，在对应输入中保留带缩进的空行。

黑盒测试验证路径长短、Unicode、分组、重名变量、不排序选项、保留文档不变性和
Go 的转义路径非幂等行为。五项可求值输入同时比较值和实际导入请求顺序，
覆盖多绑定、注释、遮蔽、未使用导入及混合普通绑定；格式化本身不读取任何导入。

## 语料与剩余差异

上一批 122 项语料全部通过，原八项差异均已消除。新增 55 项输入保留六项新差异，
故完整结果为 171/177，而非只报告已通过的旧语料。171 个有效输入的本地输出均能
重新解析；另外六个输入验证解析错误。两端均核对冻结输出和幂等性标记。

| 失败用例 | 实际差异 |
| --- | --- |
| `imports-strip-interstitial-followed-newline` | Go 的空行带缩进，本地空行无缩进 |
| `imports-strip-paragraph` | 删除块段落注释后本地多保留空行 |
| `imports-strip-line-paragraph` | 删除独立行注释后本地多保留空行 |
| `imports-equal-paths-13` | 相同路径的绑定排列与 Go 不同 |
| `imports-equal-paths-32` | 同上，覆盖更大的分区 |
| `imports-equal-paths-64` | 同上，覆盖更多重复键 |

Go 1.24.0 的 `sort.Slice` 调用 `pdqsort_func`，小数组插入排序阈值为 12；
当前 MoonBit 排序算法不同。相同路径的排列不影响已测求值语义，但仍是格式化
精确输出差异，不能自动作为兼容例外。后续需要对齐固定参考的排序路径，以及
FodderLineEnd/Paragraph/Interstitial 在删除注释时的保留和合并规则。

当前六项参考非幂等输入为 `escaped-field`、`strip-comments`、`strip-everything`、
`imports-raw-escape`、`imports-strip-tail-interstitial` 和
`imports-strip-interstitial-followed-newline`。上一份文档误将原语料的三项写成两项，
本次按已提交的冻结字段补正；没有改动参考预期或原验收计数。

## 本批验证

| 检查 | 结果 |
| --- | --- |
| `moon info`、`fmt`、native `check --deny-warn`、`fmt --check`、`doc`、release build | 通过，无接口签名变化 |
| native 调试版 / 发布版测试 | 232/232；232/232 |
| 干净提交格式化差分 | 171/177；六项失败保留 |
| 独立归档消费者 | 23/23，包含新增排序输出调用 |
| ASan | 232 项测试、183 项宿主检查、33 项依赖 fixture、13 项依赖 CLI、30 项参数、21 项本地 Evaluator 序列、173 项 AST/原始源码、23 项 lint CLI，全通过 |

ASan 使用隔离工具链、禁用 mimalloc，关闭 leak detection；目录为
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.61741.dd499237`。
新增导入排序黑盒测试在该运行中执行；177 项完整 Go 格式化差分使用发布版探针，
不宣称完整差分运行于 ASan。ASan 本地序列不替代 Go API 验收。

本批未重复运行发布版 Go CLI、C++ CLI 和完整 Go lint/AST 差分；其上一轮提交绑定的
结果见 [格式化首批验收](GO-JSONNET-FORMATTER-BASELINE.md)，不能当作本次重测结果。
历史 Go CLI 18 项、lint 一项参考崩溃和 Evaluator 导入缓存差异仍在整体计划中保留。

原始报告：`_build/formatter/report.json`；参考探针目录：
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-formatter-.61611.ec14424f`。
复现：

```sh
moon build --target native --release --deny-warn
moon run tools/formatter-integration.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012}
```

命令因六项已保留失败返回非零，全部输入与两端输出写入报告。
仅执行本地实现、验证和提交；未推送、未发布。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
