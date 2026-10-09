# CLI 导入身份与 AST 来源

2026-10-09，起点 `33d4fb7706f92453d1ed5a949693db99db1da57a`。
两个此前保留的探针都展示固定 Go 正常返回时的额外产品差异，不能归入用户批准
的19项参考崩溃例外，也不是原21行冻结输入的重复失败。

- `distinct-canonical-aliases`：两个 symlink 路径指向同一物理文件，Go按两个
  found-at 身份分别求值；旧 CLI 合并 canonical 身份，只产生一次 trace。
- `raw-alias-first`：先 importstr 别名再 import 正常路径，旧 CLI 用第一次字节
  导入的名称显示后续代码 trace。原因是代码来源和宿主字节身份共用映射。

CLI 现在把成功找到的请求路径作为导入 Source.id，按该词法父目录解析嵌套
导入。FileHost 的 canonical 安全边界、字节缓存、公共 API 均未修改；代码
求值缓存和 AST 来源因而能区分别名。导入的 thisFile、错误和 trace 都使用
代码路径，importstr/importbin 不会修改另一份 AST 的来源。入口自身的既有
canonical 执行身份保留。此处没有改变 lint 身份策略或新增例外。

远端为既有隔离目录，UID65534、CPU0–1、nice10、jobs2；固定 Go1.24.0、
go-jsonnet `67968688d9952f50662e979fab1bef889d0d3e57`，Linux AMD64。
双方同 cwd、source、argv，完整 stdout/stderr/exit 比较，不做路径归一化。

| 实际检查 | UTC | 结果 |
| --- | --- | --- |
| CLI check/test/release build | 08:48:39–08:49:25 | 零警告；11/11 |
| 旧产品44项基线 | 08:50:16–08:50:18 | 12/44，32项失败全部保留 |
| 新产品44项 | 08:50:18–08:50:19 | 44/44 |
| 既有导入 trace 及两个原探针 | 08:50:19–08:50:23 | 116/116，另2/2 |
| 导入宿主边界 | 08:50:23–08:50:25 | 20/20 |
| info/fmt | 08:50:25–08:50:26 | 退出0 |

覆盖相对/绝对入口、两个别名及顺序、重复请求、raw/binary/code 混合、惰性
字段、thisFile、symlink 父目录、搜索路径、运行时/语法错误、stream/multi。
新工具首次使用 MoonBit 保留词 alias/local，deny-warn 阻止编译；只改变量名
后复用产品二进制执行对照。首次编译错误与修正后12/44真实基线分别保存，
不能把编译失败当成行为基线。

本地原始证据位于 `${LOCAL_PATH_013}/identity-evidence`，
`resume/baseline.json`、`resume/identity.json`、`resume/trace.json` 保留完整输出。
此处仅记录定向通过；最终全量、包消费者及相关 ASan 另行验收，不转移旧提交
的全量数字。冻结 tests/ 输入与预期未改。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
