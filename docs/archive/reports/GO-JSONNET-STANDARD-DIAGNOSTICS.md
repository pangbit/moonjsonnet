# 标准库与降级表达式诊断验收

日期：2026-10-08；干净实现提交 `35a3af845d7b258e46f8bda798789dae9a1066d3`。
仅本地提交，未推送、部署或发布。

`error` 值及失败断言的消息使用有预算的 Jsonnet 字符串转换，覆盖非字符串容器、
空容器、字段排序、隐藏字段惰性、控制字符和转换中的错误。成功断言不求值消息。
类型、除零、字段、索引和函数参数错误按固定 Go 消息处理；索引保留当前 arm64
参考的 Int64 转换边界，不先将越界值缩窄为 Int。

已验证的 map/mapWithIndex/assertEqual、对象 fields/has、manifestJson、slice
改由嵌入的固定标准库源码在 MoonBit 求值，保留源帧及惰性参数。切片使用不可被
用户 `std` 局部变量覆盖的 `$std`；推导式输入/条件/键错误保存完整表达式的降级
调用帧。生成数组调用使用独立惰性 thunk，避免虚构语义 AST 节点；缓存堆回收
保留其闭包和参数，跨次求值回归通过。原有深度、工作量、帧、输出和根目录预算
继续生效，产品执行没有依赖 Go/C++ 解释器。

新增 JSON 诊断扫描器只在 MoonBit core 解析失败后运行，按 Go 1.24.0 的迭代
状态转换、首错误及 EOF 规则生成错误，字节字符引用规则也核验。YAML 解析器
区分 parser/scanner 错误，保留固定解码器的行号、锚点名和指令错误；修正重复
TAG 检查及多条不同 TAG 声明的保留，底层合法 YAML 1.1 指令测试通过。
固定 Go 的 parseYaml 会在 `---` 处分块，导致某些合法的完整指令文档被拒绝；
这些真实错误作为对照保存，没有改成成功预期。新增 libyaml MIT 许可已加入
NOTICE、独立消费者的 archive 检查和实际本地包。

原 273 项诊断 corpus 扩至 1043 项，新增错误消息转换、标准函数、降级表达式、
调用/类型/索引边界、32 项 JSON 扫描输入、20 项 YAML 输入。七种 trace 设置及
原着色检查均保留；完整字节、有序帧、错误/成功标志和输出直接比较，预期只由
固定 Go 生成，未删除旧用例或规范化错误。

| 验证 | 结果 |
| --- | --- |
| info / fmt / native 普通及 release check --deny-warn / release build / fmt --check / doc / diff --check | 全通过；根公开接口未变，internal/yaml 新增 ParserError 已核对 |
| native 普通 / release | 各 291/291 |
| 独立 archive 消费者 | 29/29；新实现与许可均在 archive 中 |
| 干净提交实际 Go 诊断 API | 1043/1043；Go/本地错误各 1008；0 跳过/未支持/声明例外 |
| 干净提交实际 Go 调试器 / AST | 26/26、173/173 |
| 干净提交冻结 / 上游格式化 / 节点编辑 | 736/736、178/178、56/56 |
| 干净提交 jsonnetfmt | 255/255，另 4 项 branding/help |
| 干净提交整体 Go CLI | 1132/1150；483 预期错误，原 18 项失败保留 |
| 干净提交 Evaluator | 20/21；原失败解析缓存差异保留 |
| 干净提交 lint | 409/410；原身份碰撞 panic 保留；CLI 两解释器各 23 检查 |
| 标准库注册反射 | 163/163；0 缺失、签名差异、额外；不代表所有行为等价 |

上述十份实际 Go 报告均为 source_dirty=false，绑定同一实现提交。固定 Go
`67968688d9952f50662e979fab1bef889d0d3e57`、Go 1.24.0、GOWORK=off、GOPROXY=off；
干净 C++ `bbb38f1020be1f5aed560928fb839b2c448cefb4` 仅提供格式化输入。
实测 macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。

ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.91843.8404ec1e`。
五个实现文件及冻结语料的 SHA-256 与隔离副本一致；隔离工具链只修改临时副本，
未安装软件或修改已安装运行时。Evaluator 的本地冻结 21/21 不替代实际 Go 20/21。
隔离 ASan 原生测试 291/291、完整既有宿主/API、formatter 宿主、节点编辑
56/56、调试器 26/26、新诊断冻结 1043/1043 全通过，未报告内存错误。
泄漏检测按现有工具合同禁用。

| 证据 | SHA-256 |
| --- | --- |
| json_diagnostic.mbt | `99d004f63c4e628a667460da380764cb53772db5ce5a0916339bf6a02f7d8837` |
| runtime_types.mbt | `aafbe17b53d06dd8776fbf694bb18f8a6fd1b000cb31bfb7d3d8598390adca75` |
| eval.mbt | `87ca689558f95e74ddb8fca5395b1490a91a016e87d460f03792b0f89c477d0a` |
| parse_yaml.mbt | `37c01860f5ba0ce64fadcbd70144873d2c15932bf648ed02f8bfe836cba7eb50` |
| internal/yaml/parser.mbt | `8ef05104ec236201a05f34f011287e839657cc6bbb18ffc888b7c6199a1f00b9` |
| tests/go-diagnostic-api.json | `c4538538fca9971177ce298d158a5cb928571070b2b5e6263d197f840ffea1b2` |
| tests/reference/diagnostic.go | `7152c46293d1bb24f04577e46cb944832674ce0904d764297a788d1993c174f7` |
| release diagnostic-probe | `e85dedff2f0ea0a28d72debc9f59bdaec41dd5c906d892260735b1f9b1377ada` |
| _build/diagnostic-api/report.json | `9a4d9f1bcb0b98e2b6adafd751c71a8ba8fbfc065f18e633ac121140b935cb50` |
| _build/debugger/report.json | `a7a663500c6b2445af141deb7b22dec3a008b404e9c607e8b0a8aed663a21b9e` |
| _build/ast/report.json | `f19724d7f9e57ce33a70d5e7e7f07433b5c3aeada48cd195bb1ecc31e1cdc084` |
| _build/go-differential/report.json | `05f83f210a938a9039b8678b0670d91aa9d95017aa74e4fe390e31560038a0d0` |
| _build/evaluators/report.json | `70db91fb6915905d21aa3823f0a172fb8ef96dc48764d5e6ec0da79676104660` |
| _build/lint/report.json | `d42da2fdb5dcdc05f13d97796e49066b252cd869e7a66b6c942b7996efb39114` |
| _build/formatter/report.json | `bd0d131ae50c0e2dfb3e7bf03da95e49a98921d8a6a21200ff36440eac175595` |
| _build/upstream-formatter/report.json | `3d2c9e6453ea1645249aeea3d4f91fe0e2c00f44db1eccd9f3a0f93034b2b69a` |
| _build/formatter-node/report.json | `cfb637a6107436a1b18be1ad6b380eacd2d88b26687b5082d15026180c77c5d7` |
| _build/formatter-cli/report.json | `d950a0f9444eb181464d29640cbe5bb0c78e1ab026490c13989a7fec9965984d` |

整体对齐尚未完成：CLI 仍使用旧渲染合同，其他标准库错误、降级帧与原始 AST
调试断点范围还需覆盖；Linux 缺少可用编译器，新增环境/安装需先报告。18+1+1
项参考差异尚未被用户接受为例外，仍全部保留失败。
