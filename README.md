# UVM Environment Generator (uvm_gen.py)

## 版本信息
- **版本**: v1.1.0
- **更新日期**: 2026-03-15
- **Python 版本**: 3.6+
- **许可证**: MIT

## 简介

uvm_gen.py 是一个基于 YAML 配置文件的 UVM（Universal Verification Methodology）测试台自动生成工具。该工具能够从配置文件自动生成完整的 UVM 测试台结构，包括 Agent、Interface、Transaction、Environment、Scoreboard 等组件。

## 主要功能

### ✅ 已支持功能

#### 1. **配置驱动生成**
- 基于 YAML 配置文件生成整个 UVM 测试台
- 支持自定义输出目录
- 支持多 Agent 配置
- **配置文件验证** - Schema验证确保配置格式正确
- **自动备份** - 生成前自动备份现有输出目录

#### 2. **组件生成**
- **Agent 组件**: Driver、Monitor、Sequencer、Agent
- **数据组件**: Interface、Transaction Item
- **环境组件**: Environment、Config、Virtual Sequencer
- **验证组件**: Reference Model、Scoreboard、Coverage Collector
- **测试用例**: Base Test、Sanity Test
- **仿真脚本**: Makefile、run.tcl、cm.cfg

#### 3. **RTL 解析**
- 自动解析 RTL 文件提取端口信息
- 支持基本端口类型（input、output、inout）
- 支持端口宽度和方向解析
- **增强错误处理** - 详细的错误日志和警告信息

#### 4. **模板系统**
- 使用 Mako 模板引擎
- 16 种预置模板
- 支持自定义模板扩展（需修改代码）

#### 5. **错误处理与日志**
- **完整的日志系统** - 支持调试模式和普通模式
- **自动备份机制** - 生成失败前自动备份现有文件
- **回滚功能** - 发生错误时自动回滚已生成文件
- **详细错误报告** - 提供生成统计和组件分解报告

### 🚧 待开发功能（规划中）

#### 高级功能
1. **配置增强**
   - [ ] 配置文件继承和复用
   - [ ] 配置模板和预设
   - [ ] 配置版本控制
   - [ ] Schema 验证（使用 Pydantic）

2. **RTL 解析增强**
   - [ ] 支持 SystemVerilog 接口（interface）
   - [ ] 支持参数化模块
   - [ ] 支模块数组（parameterized arrays）
   - [ ] 更复杂的端口解析

3. **模板系统增强**
   - [ ] 自定义模板支持
   - [ ] 模板缓存机制
   - [ ] 条件渲染支持
   - [ ] 模块化模板组织

4. **用户体验**
   - [ ] 命令行界面增强
   - [ ] 交互式配置生成
   - [ ] 可视化测试台结构预览
   - [ ] 详细的使用教程

#### 性能优化
1. **性能优化**
   - [ ] 增量更新支持
   - [ ] 并行生成支持
   - [ ] 模板预编译
   - [ ] 内存使用优化

2. **错误处理**
   - [ ] 完整的异常处理
   - [ ] 详细错误报告
   - [ ] 回滚机制
   - [ ] 日志系统

3. **扩展性**
   - [ ] 插件架构
   - [ ] 自定义组件生成器
   - [ ] 第三方工具集成
   - [ ] API 接口

## 安装要求

### Python 依赖
```bash
pip install mako pyyaml
```

### 系统依赖
- Python 3.6+
- GNU Make
- TCL (用于仿真)

### 环境变量
```bash
export UVM_GEN_DIR=/path/to/uvm_gen/templates
```

## 使用方法

### 1. 准备配置文件

创建 `config.yml` 配置文件，参考 `config.yml` 示例：

```yaml
output_dir: /path/to/output

rtl:
  top_file: "/path/to/design.v"
  top_module: "my_design"
  flist: "/path/to/files.f"

testbench:
  name: tb_top
  timescale: "1ns/1ps"
  dut_instance: "DUT"

test:
  base_name: tc_base_test
  sanity_name: tc_sanity

agents:
  - name: master_agent
    mode: active
    type: in
    interface: my_if
    item: my_item
```

### 2. 运行脚本

```bash
# 使用默认配置文件
python uvm_gen.py

# 指定配置文件
python uvm_gen.py -c /path/to/config.yml

# 启用调试模式（显示详细日志）
python uvm_gen.py -c /path/to/config.yml -d
```

### 3. 生成的文件结构

```
output/
├── uvm_tb/
│   ├── interfaces/
│   │   └── my_if.sv
│   ├── items/
│   │   └── my_item.sv
│   ├── master_agent/
│   │   ├── master_agent_driver.sv
│   │   ├── master_agent_monitor.sv
│   │   ├── master_agent_sequencer.sv
│   │   └── master_agent.sv
│   ├── top_cfg.sv
│   ├── virtual_sequencer.sv
│   ├── ref_model.sv
│   ├── scoreboard.sv
│   ├── coverage.sv
│   ├── chip_env.sv
│   └── tc_top.sv
├── uvm_tc/
│   ├── seq/
│   │   └── master_sequence.sv
│   ├── tc_base_test.sv
│   └── tc_sanity.sv
└── rsim/
    ├── Makefile
    ├── run.tcl
    ├── cm.cfg
    ├── flist.txt
    └── tb.f
```

### 4. 仿真

```bash
cd output/rsim
make sim
```

## 配置文件说明

### 主要配置项

| 配置项 | 说明 | 类型 | 必需 |
|--------|------|------|------|
| output_dir | 输出目录 | string | 是 |
| rtl.top_file | RTL 顶层文件路径 | string | 是 |
| rtl.top_module | RTL 顶层模块名 | string | 是 |
| rtl.flist | 文件列表路径 | string | 是 |
| testbench.name | 测试台文件名 | string | 是 |
| testbench.timescale | 时间尺度 | string | 是 |
| testbench.dut_instance | DUT 实例名 | string | 是 |

### Agent 配置

```yaml
agents:
  - name: agent_name          # Agent 名称（唯一）
    mode: active/passive      # Agent 模式
    type: in/out             # 类型
    interface: if_name       # 关联接口
    item: item_name          # 关联 transaction item
```

### 接口配置

```yaml
interfaces:
  - name: if_name            # 接口名称
    clock: clk_name          # 时钟信号
    clk_period: 10ns         # 时钟周期
    reset: rst_name          # 复位信号
    signals:                 # 信号列表
      - name: signal_name
        type: logic[31:0]
        dir: input/output
```

### Transaction Item 配置

```yaml
items:
  - name: item_name          # Item 名称
    fields:                  # 字段列表
      - name: field_name
        type: "logic[31:0]"  # 类型
        rand: true/false     # 是否随机化
```

## 故障排除

### 常见问题

1. **Module not found**
   - 检查 `rtl.top_module` 是否正确
   - 确认 RTL 文件路径是否存在
   - 查看日志文件 `uvm_gen.log` 获取详细信息

2. **Port parsing failed**
   - 确认 RTL 文件格式正确
   - 检查端口声明语法
   - 启用调试模式查看解析详情

3. **Template not found**
   - 检查 `UVM_GEN_DIR` 环境变量设置
   - 确认模板文件存在
   - 检查模板目录权限

4. **YAML parsing error**
   - 检查 YAML 语法
   - 确认缩进正确
   - 使用 Schema 验证配置文件

5. **Configuration validation failed**
   - 检查必需配置项是否完整
   - 验证 Agent、Interface、Item 之间的关联性

### 调试模式

使用 `-d` 或 `--debug` 参数启用调试模式：
```bash
python uvm_gen.py -d
```

调试模式会显示：
- 详细的解析过程
- 每个组件的生成状态
- 端口解析详情
- 模板渲染过程

### 日志文件

脚本会生成 `uvm_gen.log` 日志文件，包含：
- 所有操作的时间戳
- 错误和警告信息
- 生成进度跟踪
- 详细的调试信息

## 开发指南

### 修改模板

1. 编辑 `templates/` 目录下的 `.mako` 文件
2. 使用 Mako 语法（`${variable}` 和 `% for item in items:`）
3. 保持模板结构的一致性

### 添加新组件

1. 在 `config.yml` 中添加新配置项
2. 创建对应的 `.mako` 模板
3. 在 `UVMGenerator` 类中添加生成方法

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具。

## 更新日志

### v1.1.0 (2026-03-15)
- **新增配置文件验证** - Schema验证确保配置格式正确
- **改进错误处理** - 完整的异常处理和详细的错误报告
- **添加日志系统** - 支持调试模式和普通模式日志记录
- **自动备份机制** - 生成前自动备份现有输出目录
- **回滚功能** - 发生错误时自动回滚已生成文件
- **增强RTL解析** - 更好的端口解析和错误提示
- **详细生成报告** - 统计生成的组件数量和文件结构

### v1.0.0 (2026-03-15)
- 初始版本发布
- 支持基本 UVM 组件生成
- 支持 RTL 解析
- 支持 YAML 配置文件