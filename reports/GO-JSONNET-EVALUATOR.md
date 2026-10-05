# 可重用 Evaluator 验收

2026-10-05，在实现提交 `c0475812a28a8a4bb84ef1250c74b5589f26df4f` 和干净工作区
执行验收。参考 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**整体对齐未完成；本批补齐可重用配置、导入值缓存及相应失效生命周期。**

## 实现范围

- 公开 `Evaluator`，执行已解析 Program 并提供 JSON、文本、文档流和 multi
  四种结果。入口每次重新执行，已导入代码结果跨次保留。既有全局和 Program
  方法保持每次独立；输出实现提取为共享内部函数，未复制不同序列化实现。
- ext/TLA 的 JSON、代码和 Program setter 替换同名旧绑定，reset 清相应配置。
  ext setter/reset 与 native 注册清值缓存，保留 source/AST；TLA、trace、
  string-output 和 Limits 配置保留缓存；替换 importer 清全部导入状态。
  即使重复设置相同 ext 值，也会失效缓存，与固定 Go setter 一致。
- 缓存的对象字段、闭包、数组及已成功部分继续可用。普通失败 thunk 和字段
  在下次执行重试；对象断言错误则随对象保留，直到值缓存被清除。诊断快照
  单独复制，后续调用或用户修改旧结果不会追加到缓存中的 context。
- 每次执行重置资源计数，并对直接请求的缓存源码重新检查源字节/导入预算。
  已就绪值不重新执行原计算；独立 depth/steps 等政策仍属于宿主资源限制。
  同一实例拒绝回调中的重入和配置修改，报结构化 Runtime 错误。
- 执行后从导入结果标记可达对象/thunk，释放不可达入口临时值并复用空槽。
  闭包环境、对象字段/局部作用域、自引用、继承和数组成员均纳入可达关系；
  清值缓存同时释放这些运行时对象。新导入身份和新求值字段仍可能使缓存增长。

参考依据为 Go `vm.go` 的配置 setter/flushCache/flushValueCache，`imports.go`
的 source/AST/code 缓存，`thunks.go` 的失败重试，以及 `value.go` 的
setAssertionsCheckResult。没有把 Go/C++ 二进制作为运行依赖。

## 对照发现与验证

首轮扩展到 11 组时为 10/11：初始实现将对象断言失败也重试，固定 Go 则重复
返回同一失败且不再调用 native。检查参考源码后，加入独立断言错误缓存，并
补充 ext 变更使其失效后恢复的步骤。修正后 11/11 全部通过。原失配报告保留
在 `_build/evaluators/assertion-failure-before.json`，未删除该输入。

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；公开接口只新增 Evaluator 及方法 |
| debug / release 测试 | 各 174/174；新增 10 项回归及 1 项文档测试 |
| Go VM 生命周期对照 | 11/11 序列；49 次求值，其中 7 次预期错误 |
| 既有 Program 参数 API 对照 | 30/30 |
| Go CLI 差分 | 1112/1130；原 18 项失败保留，0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 183 项通过 |
| 依赖工具 | 33/33 fixture + 13/13 本地 CLI 检查 |
| 独立归档消费者 | 18/18，执行公开 Evaluator 四种输出 |
| 隔离 ASan | 174 测试 + 183 宿主集成 + 33 依赖 fixture + 13 CLI 检查 + 30 参数 fixture + 11 Evaluator 序列通过 |

序列固定每次求值的结果、错误状态、native 调用数、实际源读取数和 trace
消息/sink 标签，涵盖缓存失效、惰性字段、错误重试、断言错误、继承局部变量、
递归闭包、数组变更、部分成功保留及缓存顶层函数的 TLA。参考适配器使用缓存
不可变 Contents 的 importer；源读取数不等于原始 importer 回调调用数。
完整进程输出和诊断保存，诊断片段检查不是 Go 帧集合/文本完全相同的证明。

白盒测试在固定导入对象/函数工作量预热后连续执行 200 次，thunk/object 槽位数
保持不变，并核验临时状态回收和 ext 失效后的 source/AST 保留。另有无导入
递归与缓存递归闭包检查。此证据限于内部槽位，不构成 RSS、通用内存上界或
泄漏检测结论。

ASan 使用隔离工具链副本及已提交的跟踪源码，全部测试和 probe 使用
`exitcode=99`，关闭 leak detection。隔离副本没有 .git，API 本地报告将 Git
元数据记为 null；本次副本来源为上述实现提交，没有改动已安装工具链。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- 本地 release 解释器 SHA-256：
  `aa1f8424e681ae81eece1e8d1b05cf345f0abf9c27cff3bbd0557ad3a7dcb614`。
- 本地 release 依赖工具：
  `6792e33f24dcdd22845f09c461f5ef99c8676fbe2f9eeabfba8c64ceea05e906`。
- 本地 release Evaluator probe：
  `2926b548458bcf66f5c5d899a890a698087dfa88c39910aa186485dc0cff1614`。
- Go Evaluator adapter：
  `15a35e3f59706756939152803b94409de4427cc0a5bc6f8d1a8cddd41d13b35c`；源码
  `8636646a62065c36f17bbc5a8ddfa2ebba17ccadd71336bac36c5e4bcefd8a29`。
- Go helper 构建前校验固定 checkout 提交及干净状态；Go 1.24.0、GOWORK=off、
  GOPROXY=off，报告保留 build metadata。helper 模块标识为 `(devel)`，参考
  提交来自显式 checkout 校验，不伪称 helper 本身含 vcs.revision。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；CLI
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/evaluators/report.json`、参数 API、Go/C++ 差分、依赖工具及标准库
  表面报告均绑定上述实现提交和 source_dirty=false；上游语言报告也绑定该提交。
- 生命周期证据目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-evaluators-.14484.aa547fb7`。
- 消费者目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.14860.6fbf88`。
- ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.15731.aa66219e`。

各语料单独计数，未合并成整体通过率。只作本地提交，没有推送或发布。
ResolveImport/ImportData/ImportAST 查询、共享状态依赖扫描、可编辑 AST、EvalHook、
完整诊断能力、格式化/lint 及其余语言/平台差距仍待补齐。现有根目录、UTF-8、
资源与非重入政策不等于 Go 的无限制宿主；未将其声明为用户已接受的最终例外。
