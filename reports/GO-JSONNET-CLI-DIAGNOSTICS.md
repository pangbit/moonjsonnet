# CLI 诊断渲染与输出/导入错误验收

日期：2026-10-08。CLI 实现 `f4850ab5d7b3d74396901a66fbfce6fc27726bbb`；
最终补修 `3810ceea7a8dc1c9ec2c689a4284fd83aa803e33`。仅本地提交，未推送、部署、发布。

CLI 为语言错误及运行时帧耗尽使用已验证的 DiagnosticFormatter：命名/合成帧、
两端裁剪、静态源码范围/片段、原始错误字节。entry/import/ext/TLA 源码按身份
注册；字符串解码不介入 stderr 字节路径。根目录、规范路径、UTF-8 和独立预算
合同保留，其他 Import/Limit 错误仍使用原宿主格式，旧 Diagnostic::format 不变。

补修字符串输出的拒绝类型、stream/multi 顶层类型、multi 字符串值的 Go 类型名。
字符串输出不强制失败容器；stream/multi 的原有遍历和预算不改。运行中的 import
编译失败保存调用帧，以 Go 运行时格式包含原编译范围；公开 Syntax/Static 类别
仍保留，直接解析仍渲染静态片段。原始错误字节包括非法 UTF-8 均保留。
公开 `.mbti` 没有变化。

新增 CLI 工具构建实际固定 Go CLI，读取每个不同诊断 API 输入及着色调用变体，
分别以 exec/stdin/规范绝对文件、七种 trace 设置运行，合计 3549 项。双方输入
和文件/import 身份完全相同，不规范化输出。stdin/stdout/stderr 原始字节及退出
码直接比较；实际源、选项、字节和所有失败保存在完整报告。

85 个旧 CLI 类别/context 断言迁移为 Go 标题或既有 Go 完整快照，原 Go 预期未改。
逐项比较原七份 fixture 的 338 个用例，输入、参数、文件、环境、Go 预期、成功
输出和文件结果均未改变。新标题也暴露输出与导入错误的真实差异，均补修并加入
独立测试；更严格的自引用 ext-code 标题检查仍失败，没有删除或放宽它。

| 验证 | 最终补修结果 |
| --- | --- |
| info / fmt / native 普通与 release check --deny-warn / release build / fmt --check / doc / diff --check | 全通过，公开接口未变 |
| native 普通 / release | 各 293/293 |
| 独立 archive 消费者 | 29/29 |
| 实际 Go CLI 完整字节 | 3549/3549；Go 错误 3444；0 跳过/未支持/声明例外 |
| 实际 Go 诊断 API | 1141/1141；Go/本地错误各 1106；0 跳过/未支持/声明例外 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt | 255/255，另 4 项 branding/help |
| 整体 CLI | 1131/1150；483 预期错误，19 项失败保留 |
| Evaluator / lint | 20/21、409/410；原各 1 项失败保留；lint CLI 两解释器各 23 检查 |
| 标准库注册 | 163/163；0 缺失/签名差异/额外，注册不代表行为全等 |

十一份实际 Go 报告均核对 source_dirty=false，绑定最终补修提交。固定 Go
`67968688d9952f50662e979fab1bef889d0d3e57`、Go 1.24.0、GOWORK=off/GOPROXY=off；
干净 C++ `bbb38f1020be1f5aed560928fb839b2c448cefb4` 只提供格式化输入。
实测 macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
三个既有可运行示例在 CLI 实现提交实际执行成功，其预期错误也执行；最终补修的
整体差分及原生测试继续覆盖这三个示例。

完整报告已复制并验证哈希至
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.90498.f302216d`。
manifest.json 包含源码身份、原报告路径、完整副本路径、通过/失败计数和下列哈希；
0–10.json 保存全部用例与实际输出，避免后续 runner 覆盖当前证据。
manifest.json SHA-256：`0fdaee02ad49994a7497e58e3522a92162522585e561e4ca98c1241c8cdd59ca`。

| 证据 | SHA-256 |
| --- | --- |
| cmd/main/main.mbt | `15c6d5d9973563362086991370f4a068769b6fc543365d5050f2c8ac48d0738d` |
| diagnostic_formatter.mbt | `bd35b6517cea3399fb5e7b4ab9198d8e249e9d1c6582b5b3ca6f14ad2ee1bee0` |
| imports.mbt | `858a6645d27ffbd6842b8223fa582764eea06cdc1bde2e2543d9325d2b6109f1` |
| output.mbt | `231859ccfb441434123c5ae9ab63aca4291dc0211e06c247402563487ecf50b4` |
| multi.mbt | `8f181a1f0b96091b41d87d719dabbbe837e72576a21d80fd21259f8e58c74807` |
| tests/go-diagnostic-api.json | `0765bc9499f733b1236739ff6200e12bcebbd51b657237786358d2b970e61b8a` |
| tools/diagnostic-cli.mbtx | `f45dc285d6212ba02fac71fd34130eb57bc83aa2a612acd4c34a1f3f623309c2` |
| release main.exe | `7f01b1ef6181a7a13bd5b934a44b0232e95cdf95bc7e1224a9d985716a58563c` |
| release diagnostic-probe | `bacddc2a107340dccee43dda0c23d04c0635f649fb5f3d1868b3d26f1f15f685` |
| CLI diagnostic report / snapshot 0 | `3fdb8f06e7c0ce03b17d27f53c4fbc00f2b288b032dcb550f105058eeb15237e` |
| API diagnostic report / snapshot 1 | `afb2e41fdb95198c40a06cc3b45d1398c2ed8bcc23797ac24c7f465fe4a39446` |
| debugger / snapshot 2 | `cb5bba031785a1f00ef1be703497985eb4becd592c23ba9f302e6af2f009af0c` |
| AST / snapshot 3 | `cd7a5b37e9debb9d421b0ce7a7c287a7ad35b9b464407b0b79598d7dc8857d5c` |
| whole CLI / snapshot 4 | `5131f0758cafd48ba4aeaa2b0a82a5829ad30cbe7789e7c44a47cb2f84a322a2` |
| Evaluator / snapshot 5 | `6135a632232f31806b468d8ad734b852bbf7e54a9f421fde2a8a38a6a34aad99` |
| lint / snapshot 6 | `be868dc94f62ce0610ef20b9d7cc5eab4481aa50be768fcd27bb560bd72798f4` |
| formatter / snapshot 7 | `70251b3b1cd2a373d093a76c843843b895c6a5e6954d37556468cb1fea7b1238` |
| upstream formatter / snapshot 8 | `11aace0aea3d0844e6c45ce7cfe5ab105f92025953907c5ad4764afc2e29f86f` |
| node formatter / snapshot 9 | `dbd535423a06abc7b34204b8d2fc98f73b9bd17164ce06094ddaa373a3656b53` |
| jsonnetfmt / snapshot 10 | `b75938f853b1b593ef85ac1527868f18413af984b7ee67a4390c64c65e02bb01` |

CLI 实现的隔离 ASan 已通过 native 291/291、完整宿主/API、诊断 API 1043/1043
及实际 Go CLI 3255/3255，副本 `.25534.96d03d0`。最终补修的隔离 ASan 同样全部
通过：native 293/293、完整既有宿主/API、诊断 API 1141/1141、实际 Go CLI
3549/3549、AST 173/173、节点编辑 56/56、调试器 26/26、lint/formatter 宿主检查。
副本为 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.71506.6181a541`；
上表五个实现文件、CLI 对照工具和冻结语料的 SHA-256 与副本一致。未报告内存错误，
泄漏检测按原合同禁用；本地冻结 Evaluator 21/21 不替代实际 Go 20/21。
工具链仅在临时副本调整分配器与 ASan 标志，未修改已安装运行时或安装新软件。

整体尚未完成。原 18 项 Go CLI/标准库崩溃差异、失败解析后的 AST 缓存差异及 lint
碰撞 panic 仍未接受为例外。新标题检查另揭示自引用 ext-code：本地立即报告
`cyclic evaluation of a lazy value`，Go 递归至 `max stack frames exceeded.`。
这是既有循环检测行为在更严格消息验收中的新失败，未改成伪造的栈耗尽消息。
其他预算边界的执行位置、全部标准库/降级断点、I/O/参数错误及终端着色仍需扩展。
Linux 尚未实测；已有镜像缺 gcc/git/curl（见历史 CONTINUATION4 报告），新增
软件/环境先报告，当前没有安装。未以 macOS 结果或 CI 定义冒充 Linux 验收。
