# 多文件输出与目录创建验收

2026-10-04 在实现提交 `06f2b47656c31dad16a5372801358a75669bd814`
及干净工作区完成验收。目标仍为 google/go-jsonnet v0.21.0，整体对齐未完成。

## 实现与边界

- `evaluate_multi` 深度 manifestation 后要求顶层对象，返回 filename/content
  映射，不访问文件系统。可见值和断言先完整检查；JSON 内容采用既有 Go CLI
  序列化并追加换行。`string_output=true` 要求各值为字符串，原样返回且不追加
  换行。全部文件共享求值状态、参数/导入缓存、native/trace 和预算。
- CLI `-m`/`--multi` 将目录前缀与字段名连接，按 UTF-8 字节词典序列出文件。
  `-m` 优先于 `-y`，可与 `-S` 组合。重复参数最后赋值有效，空目录参数报错。
  空对象不创建数据目录；若指定 `-o`，仍创建空清单文件。
- 完整求值和文件名清单预算检查在输出 I/O 前完成。每个文件名写入清单后才
  读取/写入数据，保留 Go 的部分失败行为。已有文件内容按原始字节比较，相同
  时不重写，保留修改时间；比较最多读新内容长度加一字节，不加载无界旧文件。
- `-c`/`--create-output-dirs` 为普通输出和 multi 数据创建父目录，模式 0755
  受 umask 影响。按参考行为，stream 输出和 multi 清单的父目录必须已存在。
  创建目录前采用 POSIX dirname/词法清理；实际写入路径与列出的名称不改写。
- 数据 payload 共享预算，JSON 末尾换行不计；文件名清单独立按 `output_bytes`
  检查。保留紧凑 JSON manifestation 的保守预算。求值/预算失败不打开输出，
  I/O 失败可留下已写文件或部分清单，不声明事务性。
- 输出路径、对象键、symlink 与 `..` 遵循宿主文件系统。导入 root 只限制导入
  读取；嵌入宿主自行决定输出路径政策。未声明全部 I/O 错误、竞争条件、特殊
  文件或其他平台与 Go 等价；现有文件比较保留有界读取政策。

参考源码为 `interpreter.go` 的 manifestAndSerializeMulti、evaluateMulti，
`cmd/jsonnet/cmd.go` 的 processArgs/writeMultiOutputFiles，以及
`cmd/internal/cmd/utils.go` 的 WriteOutputFile。实现使用 MoonBit 求值器及 POSIX
宿主，未调用 Go/C++ 提供运行时功能。导入搜索路径、stack/trace 选项、可重用
VM/AST、格式化及分析工具等能力仍待实现。

## 验证

| 检查 | 结果 |
| --- | --- |
| `moon check --deny-warn`、info、fmt/check、doc、release build | 通过 |
| debug / release 测试 | 各 130/130 |
| 新增 Go 差分 `tests/go-cli-multi.json` | 45/45 |
| 完整 Go 差分 | 952/970；18 失败；0 跳过/未支持 |
| C++ 原始共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库反射清单 | 163/163；0 缺失/签名差异/额外成员 |
| 宿主集成 | 原有 97 + 新增 multi 26，共 123 项通过 |
| ASan | 130 测试 + 123 集成通过；leak detection 关闭 |
| 独立归档消费者 | 12/12 |

新增差分包含 27 项成功输出、7 项求值错误和 11 项 I/O 错误，分别固定 stdout、
诊断特征和输出文件状态。Go 与本项目使用独立输出目录；初始内容、目录与
symlink 每次重新准备。清单只替换固定临时根前缀，其他字节不裁剪；文件内容
逐字节核对，`null` 表示缺失。报告保存完整 fixture、两边实际参数及观察结果，
参考创建的文件不会参与本地比较。

覆盖 JSON/原始字符串、Unicode/NUL、字段可见性与断言、文件名排序、参数、
文件/内联/stdin 输入、模式优先级、重复目录参数、创建深层父目录、空对象、
symlink、`..`/前置斜线、非法 NUL 文件名、缺少父目录、父路径为文件、部分
写入失败、求值失败保留清单及 stream 忽略 -c。状态观察工具曾因 ENOTDIR
中断；随后明确将“父路径是文件”归为该子路径不存在，保留输入和缺失预期，
其他观察错误继续中断，不转为兼容通过。

本地 API 回归另覆盖共享序列化预算、参数/缓存/native/trace、匿名起点、文本与
二进制 resolver。26 项新增集成检查将文件时间戳固定到过去，再核对 mtime/inode
以证明同内容不被重写；比较覆盖 0、1、4095、4096、4097、8192 字节，包括
旧内容较长、较短、相同及 Unicode/NUL。还验证清单精确预算与少一字节、文件
类型冲突、错误时保留已有文件、读取 symlink 和父目录创建边界。
独立消费者从真实 Mooncakes 归档调用 JSON 与原始字符串 multi 接口。

完整 Go 的 392 个 error、3 个 raw-output、58 个 text-output、45 个 file-output
及 11 个 io-error 为重叠计数。18 项历史失败原样保留，详情见
[整体对齐](../docs/GO-PARITY.md)；Go runner 因此退出 1，尚不是通过的兼容 CI
门槛。C++ 声明差异不算兼容通过，标准库注册表面也不证明全部行为等价。

## 构建与证据

- macOS arm64，Moon 0.1.20260920，MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0 构建，
  `vcs.modified=false`；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
  共享差分记录哈希；提交由本地 checkout 与上游语言工具另行核验。
- MoonJsonnet release CLI SHA-256
  `1e4330e5260e3f2f1a4bdc15dc1dc0c79f96406988a63a9a6f436922cff88ecf`。
- Go/C++/parity 原始报告均绑定上述实现提交，source_dirty=false；
  `_build/upstream-language/report.json` 同样绑定实现提交。
- ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.84710.d7648e01`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.88749.e902e8c4`。

原始报告留在 `_build`；本轮只作本地提交，未推送或发布。
其他平台和远端 CI 未在本轮验证。
