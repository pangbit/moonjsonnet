# 非尾部惰性计算重入与诊断验收

日期：2026-10-08；实现提交 `2537305d06da65a16f07b0644bdd9fb3ea381c21`。
范围依 [有限剩余清单](GO-JSONNET-REMAINING-SCOPE.md)，没有安装软件、推送或发布。

Pending、GeneratedCall、对象字段及 Code/Program 参数重入先前直接报忙状态
错误，也拒绝了能由宿主回调终止的有限递归。现在 Running 保留并执行原表达式、
生成调用或完整字段计算；加性字段保留 super 合并和原帧。每次执行都受原有帧、
表达式深度和步骤预算约束，没有伪造耗尽消息或提高默认/硬上限。只有最外层
成功才清除重试记录，内层成功、外层失败后缓存导入中的局部/生成计算可恢复。
字段失败清除缓存，hook 和帧完整展开。公开 `.mbti` 未变。

四个新测试涵盖局部/数组/普通及加性字段/生成调用的 1/2/3/8 帧耗尽、独立
深度及步骤限制、真实回调三次后终止并缓存、缓存导入外层错误后恢复、hook
平衡及 Code/Program 非尾部参数。原局部循环类别断言改为实际 Limit。
七个定位输入加生成调用/加性字段共九个固定 Go 输入，新增 63 API 及 189 CLI
项；原 1260 项输入身份及完整 Go 预期逐项核对未改。

非尾部默认调用仍受本地独立表达式深度约束，可能先于 Go 的 500 帧报告深度
Limit。完整字节对照明确使用 8 帧且低于深度预算。循环导入保护保持原合同。

| 干净实现验证 | 结果 |
| --- | --- |
| info/fmt、双模式 native check --deny-warn、release build、fmt --check、doc、diff --check | 通过；公开接口未变 |
| 普通 / release native | 各 301/301 |
| 实际 Go API / CLI 字节 | 1323/1323、4095/4095；Go 错误 1288、3990 |
| 整体 CLI / Evaluator / lint | 1132/1150、20/21、409/410；原 18+1+1 失败集合无新增 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 编辑节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI | 255/255 加 4 branding；两解释器各 23 检查 |
| archive / 原三个示例 | 29/29；环境、服务面板和嵌入 release 示例及预期错误实际执行 |
| C++ 上游语言 / 标准库反射 | 303/303；163/163 注册，0 缺失/签名差异；注册不证明行为等价 |

实际 macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9；固定 Go
`67968688d9952f50662e979fab1bef889d0d3e57` / Go 1.24.0。十一份 Go 报告及成员
报告均记录同一提交、source_dirty=false。旧上游语言 runner 仅记录提交，捕获
前后另查工作区干净，未补造 dirty 字段。十三份完整副本及 manifest 位于：
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.60801.e6f2208e`。

| 证据 | SHA-256 |
| --- | --- |
| manifest.json | cad69aadcf80ecc8cf8dc6b229fcaf5f885f62c3e88d43261d0439dc894b3ac6 |
| API 完整报告 | 5e0b5b1bddfbacee2b391d473c4e5ab7d68bc363d47ce1983b4b3bbd0b35fb40 |
| CLI 字节报告 | e92066107dc0c63234f05779b4242a9edd41a5d8e70c80c88e61b015b2dbc8a8 |
| 整体 CLI 报告 | 130f6f6a5d32ddbdf78df2029a64a16e8ad9e4e6e64db40f76d8c0e61d214708 |
| CLI release | c502a5eacfa52fbdfe608708064e6b4cb1062dac5bbf135bbad6f34099241bbe |
| API release | 575af0e878ad2e82e3d9b5c4b8fb2d5d8df2a10712a66a4fc2bb707c8146246b |
| 冻结语料 | a1ae4a6256dfe4ef98bfc221fb02d7d1c77bd3ee37f5336c8163c8fa92a7559f |

C++ 固定 `bbb38f1020be1f5aed560928fb839b2c448cefb4` 的缺失二进制使用宿主
已有 clang++/make 在既有 `/tmp` 源码内构建，未执行 install，checkout 仍干净；
二进制 SHA-256 `8e179bb0c14c977e836907f8c2eb9a6e70bba80d7ab9ec7ba25158a10c268e11`。
上游错误项仅比较退出行为，不宣称完整错误字节相同。

第一次 ASan 因 exec-server 中断失去终态，未计通过。只读命令恢复后核查已应用
补丁与完成报告，仅重跑无法确认的 ASan；重跑退出 0，完整日志
`${LOCAL_PATH_015}`，SHA-256
`101b06cf378472d2aa76edd2af48ba1118c06884f5eb5f317e0e83b6e44809ce`。
副本 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.60961.4ee5c4a3`。
native 301、宿主集成 97、multi 26、导入/诊断/独立栈各 20、实际 Go CLI 4095、
依赖 33+13、Program 参数 30、冻结 Evaluator 21、AST 173、lint CLI 23、格式化
宿主、节点 56、调试器 26、API 1323 完整通过；18 个关键源码/语料哈希相同。
按原合同禁用泄漏检测，安装运行时未改；冻结 Evaluator 21 不代替实际 Go 20/21。

剩余有限项见范围清单。终端着色已定位具体差异，单独推进；其他 CLI 参数/I/O、
现有标准库错误分支及原始/降级断点先取得具体证据。旧参考缺陷和 Linux 安装
授权仍待决定，没有标记整体完成。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
