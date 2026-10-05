# 可编辑语义 AST 验收

2026-10-05；实现提交 `458f25582d89063cc121140db1ea228db5cc67cd`，生成接口补全提交
`fba845d549a471be4554b0666fd5de38d0e47654`。最终参考验收绑定后者及干净工作区。
固定 google/go-jsonnet v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
**本批实现语义树编辑；整体对齐尚未完成。**

## 实现

- 公开 Ast/AstKind/AstField/AstClause，表示全部现有语义表达式、字段、参数、
  局部绑定和推导式。内部标准库运行时节点不暴露。Program::ast 深复制，宿主可
  替换节点及修改子数组；Ast::clone 支持独立子树（允许自由变量）。
- Program::from_ast 复制并检查形状、名称、重复参数/绑定、调用参数顺序、操作符、
  可见性、推导式和词法作用域，随后走现有 Program 执行路径。返回的 Program
  不受宿主后续编辑影响，亦不改变已缓存的导入 AST/值。支持所有输出和 ext/TLA。
- 转换使用 depth 和 steps 限制递归与节点数，循环数组返回 Limit。合成 AST 无
  源文本，保存源字节数为零；执行仍检查深度、步骤、帧、导入和输出预算。
  入口 filename/anonymous 可显式配置，节点诊断位置保留。
- 现有解析/序列调用处仅增加类型标注，以消除新公开构造器带来的推断歧义。

树不保存注释、空白、数字原文、源码范围及 Go desugared/free-variable 元数据。
本批证明构造/编辑后的语义行为，不宣称源码保真或完整 AST 表示等价。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，生成接口只增加 AST 类型和三个方法 |
| debug / release 测试 | 各 188/188，新增 6 项回归和 1 项文档测试 |
| 固定 Go AST API 对照 | 20/20，含 1 项预期运行错误 |
| Program 参数 API | 30/30 |
| Go Evaluator 序列 | 20/21，原失败解析后 nil AST 差异保留 |
| Go CLI | 1112/1130，原 18 项失败、0 跳过/未支持 |
| C++ CLI | 98 通过 + 10 声明差异，0 失败 |
| 上游语言 / 标准库表面 | 303/303；163/163 注册，仍非完整行为等价 |
| 宿主 / 依赖工具 | 183 集成；33 fixture + 13 CLI 检查通过 |
| 独立归档消费者 | 20/20，调用 AST 导出、克隆及构造方法 |
| 隔离 ASan | 188 测试 + 183 集成 + 33 依赖 fixture + 13 CLI 检查 + 30 参数 fixture + 21 本地 Evaluator 序列 + 20 AST fixture 通过 |

Go 适配器直接使用 ast.Clone、数组元素修改、Binary 构造、ExtNode/TLANode 和
Evaluate/Stream/Multi；同一输入同时验证修改前后结果。语料覆盖条件/函数/
tailstrict、断言、切片、对象继承/self/super/$、推导式、thisFile、惰性和错误。
本地另验证三种导入、非法手工树、诊断位置、匿名身份和缓存隔离。

最初 AST runner 的路径替换只替换首个匹配，误读旧参数语料；修正为全量替换后
使用独立 tests/go-ast.json 和 tests/reference/ast.go。该工具接线失败证据保留于
`_build/ast-runner-wrong-corpus-before.json`，没有将其计作语义兼容结果。
首轮提交后发现新探针的空生成接口未跟踪，报告标记 source_dirty=true；补交后
重跑全部带源码版本的参考报告。首轮存于 `_build/ast-first-validation/`。

## 版本与证据

- macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release CLI SHA-256：`f2449e62f6369dd33ce199831288d8133d40894df99a97468d9ecbc08bc9f0ad`。
- release deps：`c60bfe7b66c130e3a61c3e2c9246cac85acc77e2ddf502fd53a2dc55a75d5738`。
- release AST probe：`6f18bb9c159cad0d36e68c5203a9a6b3c42406bbb54d8ba806aaa901c27523e0`。
- Go AST helper：`f1f08b097efc6d258c3b6eed91b0f73162f43fcb42222d3daf16952105ad61f3`；
  适配器源码：`ecbc63c0e73a961fcf7a8b2bceb23dc1a6a128b3c3b2303364ea22168b5dae77`。
- Go helper 构建前校验固定 checkout 与干净状态；Go 1.24.0、GOWORK=off、
  GOPROXY=off。helper 模块为 `(devel)`，参考提交来自显式 checkout 校验。
- AST 最终证据：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-ast-.49737.4f7c1ed8`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.41160.dbd3d66e`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.40620.3564fe24`。
  副本来自 458f255 的跟踪源码；后续补交仅为空生成接口，不改变测试的可执行代码。
  使用隔离工具链、exitcode=99、关闭 leak detection，没有改动安装工具链。
- `_build/ast/report.json`、参数、Evaluator、Go/C++ 差分、依赖和表面报告均绑定
  fba845d 且 source_dirty=false；上游语言报告亦绑定该提交。原始输出和哈希保留。

各套语料独立计数，未合成“整体通过率”。调试器、源码保真、完整诊断、格式化/lint
和跨平台仍待推进；原 CLI 与 API 失败未作为已接受最终例外。仅本地提交，无推送/发布。
