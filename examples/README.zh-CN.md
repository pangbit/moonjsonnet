# 示例与验证驱动

[英文指南](README.md) · [库快速上手](../README.zh-CN.md#状态与安装)

三个应用示例演示配置生成与嵌入使用；另八个目录是开发验证驱动。它们都需要源码检出：
`examples/`、输入和测试文件有意排除在 Mooncakes 发布归档之外。注册库消费者可以直接
使用库快速上手中的程序，无需这些文件。

## 环境与工作目录

使用 macOS 或 Linux、原生 C 编译器和[已验证的 MoonBit 工具链](../README.zh-CN.md#从源码运行)。
[CI 配置](../.github/workflows/ci.yml)提供固定版本的安装命令；`moon version --all` 应显示
Moon 0.1.20260920 和 MoonBit v0.10.14+7d59c7ec9。无需另行安装 Jsonnet 解释器。

```sh
git clone https://github.com/pangbit/moonjsonnet.git
cd moonjsonnet
moon version --all
moon check --target native --frozen --deny-warn -j 1
```

以下命令都从仓库根目录执行。示例使用仓库内的文件，不是当前子目录中的同名文件。
`--frozen` 使用已经安装的 SDK 和已有依赖，不负责安装工具链。原生编译还需要平台的
C 构建工具。`main` 会继续更新；复现问题时请记录 `git rev-parse HEAD`。

## 多环境配置

[environments/main.jsonnet](environments/main.jsonnet) 导入
[template.libsonnet](environments/template.libsonnet)。模板函数共享应用名与区域，默认使用
一个副本，并根据 `self.environment` 生成端点。入口覆盖生产环境副本数，再补上各环境的
调试设置。两个文件需要一起保留；只复制入口文件会导致导入失败。

```sh
moon run --target native --frozen cmd/main -- examples/environments/main.jsonnet
```

完整 JSON 值保存在 [expected.json](environments/expected.json)：

```json
{
  "development": {
    "app": "checkout", "region": "local", "environment": "dev",
    "replicas": 1, "endpoint": "https://dev.example.test", "debug": true
  },
  "production": {
    "app": "checkout", "region": "local", "environment": "prod",
    "replicas": 3, "endpoint": "https://prod.example.test", "debug": false
  }
}
```

修改入口中的函数调用即可增加环境或覆盖 `replicas`。示例只生成本地 JSON，端点是数据，
不会部署应用或发送网络请求；模板也不验证部署平台的格式要求。若要写入新文件：

```sh
moon run --target native --frozen cmd/main -- --root examples/environments -o result.json main.jsonnet
```

请选择尚未使用的输出文件名。受限导入根包含入口与模板；文件和输出规则见
[CLI 说明](../docs/reference/CLI.md)。

## 批量面板配置

[dashboards/main.jsonnet](dashboards/main.jsonnet) 使用 `importstr` 和 `std.parseJson`
读取 [services.json](dashboards/services.json)，通过函数以及数组、对象推导式生成面板和
名称到端口的映射。两个输入文件需要一起保留。运行：

```sh
moon run --target native --frozen cmd/main -- examples/dashboards/main.jsonnet
```

完整 [expected.json](dashboards/expected.json) 为：

```json
{
  "title": "Services",
  "panels": [
    {"id": 1, "title": "checkout requests", "target": "checkout:8080", "tags": ["http", "local"]},
    {"id": 2, "title": "catalog requests", "target": "catalog:8081", "tags": ["http", "local"]}
  ],
  "byName": {"checkout": 8080, "catalog": 8081}
}
```

修改服务数组即可改变生成的面板。示例对象包含字符串 `name` 和数值 `port`；名称应唯一，
否则无法形成 `byName` 对象。面板编号跟随输入顺序。这是示意 JSON 结构，不承诺可直接导入
某个面板产品；不会连接服务、监听端口或检查服务是否存在。

## 嵌入式应用

[embedded/main.mbt](embedded/main.mbt) 导入公开的 `pangbit/moonjsonnet` 和
`pangbit/moonjsonnet/fs` 包。程序在相对根 `examples/embedded/config` 内加载
[config/main.jsonnet](embedded/config/main.jsonnet)，再由它导入
[defaults.libsonnet](embedded/config/defaults.libsonnet)。请保留可执行包和两个配置文件。

```sh
moon run --target native --frozen examples/embedded
```

第一行输出以下 JSON 值，字段顺序不影响含义：

```json
{"app":"checkout","port":8080,"retries":3,"replicas":3}
```

随后程序会有意捕获三个错误，并将诊断打印到**标准输出**：

1. 字符串 `"bad"` 导致包含 `replicas must be numeric` 的 `Assertion`。
2. 数值 `0` 导致包含 `replicas out of range` 的 `Assertion`。
3. 尝试解析导入根之外的 `../../../moon.mod` 导致 `Import`。

这些都是预期演示。有效求值与三个错误检查都成功，示例才正常退出。位置和调用栈可能占用
多行；非预期结果会抛出未捕获错误。这里有意打印的诊断与 CLI 的错误通道不同：CLI 将错误
写入标准错误，并返回非零退出状态。

有效调用通过 `ext_vars` 传入 JSON 数值 `replicas`；配置要求它是 1 至 10 之间的数值。
缺少该外部变量也会失败。等效的有效 CLI 调用为：

```sh
moon run --target native --frozen cmd/main -- --root examples/embedded/config --ext-code replicas=3 main.jsonnet
```

修改 MoonBit 入口中的 `Json::number(3)` 或 CLI 表达式，可尝试其他有效值。文件宿主提供
受控导入，资源限制与根路径检查不等于通用安全沙箱。详见[嵌入 API](../docs/reference/API.md)
与[安全边界](../SECURITY.md)。

## 检查示例输出

```sh
moon test --target native --frozen --deny-warn -j 1 --no-parallelize -p pangbit/moonjsonnet/examples
```

[examples_test.mbt](examples_test.mbt) 将前两个程序的结果与已提交的预期 JSON 比较，并将
嵌入式结果与独立字面量比较；同时检查缺失或无效参数、资源限制与根路径逃逸。比较忽略
JSON 对象顺序和排版。主动改变输入后，应审查对应预期输出，不能只为消除失败而更新预期。

## 开发验证驱动

以下八个可执行包从标准输入接收 JSON 夹具，并输出 JSON 观察结果。它们是内部测试适配器，
不属于额外应用教程或稳定的公开协议。对应工具负责构造输入并检查结果；不提供夹具而直接
启动驱动，不能形成有效冒烟检查。可选 Go 对照需要[验收说明](../docs/development/VALIDATION.md)
中指定的固定参考源码。

| 目录 | 用途 | 夹具执行工具 |
| --- | --- | --- |
| [ast-probe](ast-probe/main.mbt) | 语法树导入、变换与求值 | [ast-integration.mbtx](../tools/ast-integration.mbtx) |
| [debugger-probe](debugger-probe/main.mbt) | 断点、单步、变量观察与终止 | [debugger-integration.mbtx](../tools/debugger-integration.mbtx) |
| [diagnostic-probe](diagnostic-probe/main.mbt) | 诊断排版、调用栈与输出模式 | [diagnostic-api.mbtx](../tools/diagnostic-api.mbtx) |
| [evaluator-probe](evaluator-probe/main.mbt) | 可复用求值器设置、导入与缓存状态 | [evaluator-integration.mbtx](../tools/evaluator-integration.mbtx) |
| [formatter-node-probe](formatter-node-probe/main.mbt) | 格式化及原始树节点、范围操作 | [formatter-node.mbtx](../tools/formatter-node.mbtx) |
| [formatter-probe](formatter-probe/main.mbt) | 源码格式化与原始树重建 | [formatter-integration.mbtx](../tools/formatter-integration.mbtx) |
| [lint-probe](lint-probe/main.mbt) | 静态分析与检查诊断 | [lint-integration.mbtx](../tools/lint-integration.mbtx) |
| [parameter-probe](parameter-probe/main.mbt) | 外部参数、顶层参数与嵌入输出模式 | [parameter-integration.mbtx](../tools/parameter-integration.mbtx) |

示例和差分结果只覆盖已提交输入，不能证明完整 Jsonnet 规范符合性；请同时阅读
[当前兼容边界](../docs/reference/COMPATIBILITY.md)。
