# 求值 Hook 与同步调试器验收

日期：2026-10-08；干净实现提交 `bc098b54acbf706d2647ade3ad4c1817c76f290e`。
仅本地提交，未推送、部署或发布。此前 Raw AST 与格式化实现没有重复应用。

新增 Evaluator::set_eval_hook、EvalContext、DebugValue 和同步 Debugger。
Hook 对被实际要求的语义表达式发送 before/after，成功值保持惰性，失败诊断独立
复制。上下文和值句柄在回调结束后失效；范围/ID、独立 AST、返回文本和 JSON
可保留。变量视图按捕获作用域显示，保留遮蔽名称与内部 $std，实际运行时查找不变。
peek 和 display 不强制子值，lookup/json 是明确的求值操作。检查抑制递归 hook，
沿用工作量、深度、运行时栈和输出限制，AST 复制与完整声明遍历也计入工作量。
替换 hook 保留缓存，配置/求值重入拒绝，回调失败后能恢复执行。

调试器支持断点设置/查询/清除、Step/Continue/Finish/Terminate、异常停点和
局部值检查；宿主回调可以等待 UI/终端输入，执行结束恢复旧 hook。断点位置来自
语义树，不声明覆盖 Go raw AST 的每个括号或合成节点；display 的占位文本也是
本地接口合同。完整命名/合成诊断帧与诊断配置继续推进，没有用本阶段替代整体目标。

新增固定 Go 公开调试器 API 适配器及 26 项完整结果对照：有序停点原因/范围/
变量/标量查询、输出/错误标志、断点状态。涵盖默认及命名参数、捕获、遮蔽、惰性、
递归、对象、对象局部与方法、异常和终止。扩大对象语料时发现的两项多余作用域
变量差异已修复，原始 Go 预期没有放宽。诊断全文另存，不声明其文本等价。

| 验证 | 结果 |
| --- | --- |
| info / fmt / native check --deny-warn / release build / fmt --check / doc / diff --check | 通过；公开接口新增 Hook/检查/调试器 |
| native 普通 / release | 各 280/280 |
| 独立 archive 消费者 | 27/27，调用新增公开方法与 README 示例 |
| 干净提交实际 Go 调试器 | 26/26；Go/本地错误结果各 3；0 跳过/未支持/声明例外 |
| 干净提交语义 AST | 173/173 |
| 干净提交冻结 / 上游格式化 / 节点编辑 | 736/736、178/178、56/56；上游 Go/本地错误均 0 |
| 干净提交 jsonnetfmt | 255/255；另 4 项 branding/help |
| 干净提交整体 Go CLI | 1132/1150；483 预期错误，原 18 项失败保留 |
| 干净提交 Evaluator | 20/21；88 观察、62 求值、26 查询、10 预期错误，原失败解析缓存差异保留 |
| 干净提交 lint | 409/410；位置 190/190，原碰撞 panic 保留；CLI 每解释器另 23 检查 |
| 隔离 ASan | native 280/280、完整既有宿主/API、新 formatter 宿主、节点编辑 56/56、新调试器冻结 26/26 全通过；leak 检查禁用 |

九份 Go 原始报告 source_dirty=false，均绑定上述实现提交。固定参考
`67968688d9952f50662e979fab1bef889d0d3e57`；Go 1.24.0、GOWORK=off、GOPROXY=off，
checkout 干净。C++ 输入 checkout `bbb38f1020be1f5aed560928fb839b2c448cefb4`。
实测 macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。

ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.25305.2f0d83f9`。
四个新增实现文件与副本 SHA-256 一致。ASan 中 Evaluator 21/21 是本地冻结检查，
不能替代实际 Go 20/21；ASan 调试器也明确写 local-report.json，不混用参考证据。

| 证据 | SHA-256 |
| --- | --- |
| eval_hook.mbt | `7688fe5c6a8e3f3c78670e7578b25a9847e064e3c075320ebc6e9e0c9fe561c2` |
| debug_scope.mbt | `ce16c9aafe65c213b37ea69a4dded4bb413e5f20dd0553f86cf61951e08a7601` |
| debug_value.mbt | `1b399525509ed29ae26111456d6666eb05095007d358a7a9f7ecedf402ec2d54` |
| debugger.mbt | `b127127e615a7a7a3dc0395ad9a7a47780704ebebbf2382e9134da2264a260e1` |
| tests/go-debugger.json | `e811bd9c211683410d2885d83f0372cce04b232f2b953a3a8bef282f4a8a9f34` |
| tests/reference/debugger.go | `459bf9926af76ad83de883a0b91023e910b4341dc84b7bb53f8e8867e53371c2` |
| release debugger-probe | `586f541c1dc5403cb9ab2524732503bc4da36c15e00f77e22010e19584bc3123` |
| _build/debugger/report.json | `47ae301dea0f0817e506ced502cc283b8ed77411a84a39a288c6f2a8dbc53c53` |
| _build/ast/report.json | `17f6de0b2b60fd4736351ab27b3278eea1f097c6431d99afbb4a458c00d649ab` |
| _build/evaluators/report.json | `9eb383415f6d1457caaf6f3d2843601c47e4465eb92be0a9e56aa2cbb815e8cb` |
| _build/go-differential/report.json | `66a55f8b184e288ffa76e3d672c6c9d4d16db9c45924b66d53addc6f333da49d` |
| _build/lint/report.json | `169f944fc6d30a2f7396fe1a1c09d88ffa27f7b8721cc7c0833a868ccc13cf37` |
| _build/formatter/report.json | `82151edbe15be98c6fdf51889043b059620681e789df917832514f68c3414cbf` |
| _build/upstream-formatter/report.json | `eeb11d13eb72ce910cf22ac283488c2acd7b9efdedc47c774cb823b2318fdfe5` |
| _build/formatter-cli/report.json | `e7c53cea745281848893dd090e7a88c68044ba0fecdaf74ed3b7efe3932a806d` |
| _build/formatter-node/report.json | `9ad9fb58016db44c78855694e1a1937b18335ed58f9b54baaef38d745077ec60` |

未安装新软件、创建新平台环境或扩大权限。Linux 实测、完整诊断及最终整体交付
继续待验收；18+1+1 参考差异仍未获用户接受为例外，没有删除或算作通过。
