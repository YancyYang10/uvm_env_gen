# UVM Environment Generator (uvm_gen.py)

## 版本信息
- **版本**: v1.2.1
- **更新日期**: 2026-03-19
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
- **🆕 紧凑配置格式** - 支持简化的配置写法，减少配置文件行数

#### 2. **组件生成**
- **Agent 组件**: Driver、Monitor、Sequencer、Agent
- **🆕 Agent 实例化**: 同一 Agent 类型支持多次实例化，避免代码冗余
- **数据组件**: Interface、Transaction Item
- **环境组件**: Environment、Config、Virtual Sequencer
- **验证组件**: Reference Model、Scoreboard、Coverage Collector
- **测试用例**: Base Test、Sanity Test
- **仿真脚本**: Makefile、run.tcl、cm.cfg

#### 3. **RTL 解析**
- 自动解析 RTL 文件提取端口信息
- 支持基本端口类型（input、output、inout）
- **🆕 支持参数化模块** - 解析 `module #(...)` 格式
- **🆕 支持参数化端口宽度** - 如 `[DATA_WIDTH-1:0]`
- 支持端口宽度和方向解析
- **增强错误处理** - 详细的错误日志和警告信息

#### 4. **Transaction Item 增强** 🆕
- **do_compare()** - 字段级精确比对
- **do_pack()/do_unpack()** - 字节流转换，支持 Scoreboard 比对
- **do_print()** - 详细打印信息
- **约束块支持** - 可配置 constraint 块

#### 5. **Coverage 增强** 🆕
- **bins 定义** - 精确控制覆盖率目标
- **ignore_bins** - 排除无效值
- **illegal_bins** - 标记非法值
- **transition_bins** - 状态转换覆盖

#### 6. **模板系统**
- 使用 Mako 模板引擎
- 16 种预置模板
- 支持自定义模板扩展（需修改代码）

#### 7. **错误处理与日志**
- **完整的日志系统** - 支持调试模式和普通模式
- **自动备份机制** - 生成失败前自动备份现有文件
- **回滚功能** - 发生错误时自动回滚已生成文件
- **详细错误报告** - 提供生成统计和组件分解报告

#### 8. **🆕 安全增强** (v1.2.1)
- **环境变量自动修正** - 检测 `UVM_GEN_DIR` 版本不匹配时自动修正
- **配置文件安全检查** - 路径/权限/大小验证
- **输出目录安全检查** - 防止写入系统目录
- **模板版本一致性** - 确保使用正确版本的模板文件

### 🚧 待开发功能（规划中）

#### 高级功能
1. **配置增强**
   - [ ] 配置文件继承和复用
   - [ ] 配置模板和预设
   - [ ] Schema 验证（使用 Pydantic）

2. **RTL 解析增强**
   - [ ] 支持 SystemVerilog 接口（interface）
   - [ ] 支持模块数组（parameterized arrays）

3. **模板系统增强**
   - [ ] 自定义模板支持
   - [ ] 模板缓存机制
   - [ ] 条件渲染支持

4. **用户体验**
   - [ ] 命令行界面增强
   - [ ] 交互式配置生成
   - [ ] 可视化测试台结构预览

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
export UVM_GEN_DIR=/path/to/uvm_gen
```

**🆕 自动修正** (v1.2.1): 如果环境变量未设置或指向错误版本，脚本会自动修正为当前脚本所在目录，并发出警告。

```
WARNING - UVM_GEN_DIR (/path/to/old_version) does not match
          script directory (/path/to/current_version).
          Auto-correcting to script directory to prevent template version mismatch.
```

## 使用方法

### 1. 准备配置文件

创建 `config.yml` 配置文件，支持**标准格式**和**紧凑格式**：

#### 标准格式（向后兼容）

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

#### 🆕 紧凑格式（推荐）

```yaml
# === 基本配置 ===
output_dir: ./demo
rtl:
  top_file: "rtl/design.v"
  top_module: my_design
  flist: "rtl/rtl.f"

testbench: { name: tb_top, timescale: "1ns/1ps" }
test: { base: tc_base, sanity: tc_sanity }
env: { name: chip_env, coverage: true, scoreboard: true }

# === Interfaces (紧凑信号格式) ===
interfaces:
  ahb_if:
    clock: aclk
    reset: hrst_n
    signals: { haddr: o32, hsel: o1, hwdata: o64, hrdata: i64 }
    # o=output, i=input, 数字=位宽

# === Items ===
items:
  ahb_item:
    - { name: addr, type: logic[31:0], rand: true }
    - { name: data, type: logic[63:0], rand: true }
  apb_item:
    - { name: paddr, type: logic[15:0] }

# === Agent 模板化 ===
agent_types:
  ahb_agent: { interface: ahb_if, item: ahb_item }
  apb_agent: { interface: apb_if, item: apb_item, mode: passive }

agents:
  ahb_agent: [ahb_master_0, ahb_master_1]
  apb_agent: [apb_slave_0, apb_slave_1(mode=active)]

# === Coverage 简化 ===
coverage:
  ahb_if:
    - { name: addr_cp, expr: haddr, bins: {[0:0xFFF], [0xF000:0xFFFF]} }
    - { name: burst_cp, expr: hburst }
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
│   ├── ahb_agent/              # 🆕 只生成一套代码
│   │   ├── ahb_agent_driver.sv
│   │   ├── ahb_agent_monitor.sv
│   │   ├── ahb_agent_sequencer.sv
│   │   └── ahb_agent.sv
│   ├── apb_agent/
│   │   └── ...
│   ├── top_cfg.sv
│   ├── virtual_sequencer.sv
│   ├── ref_model.sv
│   ├── scoreboard.sv
│   ├── coverage.sv
│   ├── chip_env.sv
│   └── tc_top.sv
├── uvm_tc/
│   ├── seq/
│   │   └── ahb_sequence.sv
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

### 🆕 Agent 配置（新格式）

**类型定义**（只生成一套代码）:
```yaml
agent_types:
  ahb_agent: { interface: ahb_if, item: ahb_item, mode: active }
```

**实例化**（多次实例）:
```yaml
agents:
  ahb_agent: [master_0, master_1, slave_0(mode=passive)]
```

### 🆕 Interface 配置（紧凑格式）

```yaml
interfaces:
  ahb_if:
    clock: aclk
    reset: hrst_n
    signals: { haddr: o32, hsel: o1, hburst: o2, hrdata: i64 }
    # o32 = output [31:0], i64 = input [63:0], o1 = output
```

### 🆕 Transaction Item 配置（增强）

```yaml
items:
  ahb_item:
    fields:
      - { name: addr, type: logic[31:0], rand: true }
      - { name: data, type: logic[63:0], rand: true }
    constraints:                  # 🆕 约束块
      - name: addr_align
        expr: "addr % 4 == 0"
      - name: valid_burst
        expr: "burst_type inside {[0:3]}"
```

生成的 Item 包含：
- `do_compare()` - 字段级比对
- `do_pack()` / `do_unpack()` - 字节流转换
- `do_print()` - 详细打印
- `constraint` 块

### 🆕 Coverage 配置（增强）

```yaml
coverage:
  ahb_if:                         # 自动推断 clock/reset
    - name: addr_cp
      expr: haddr
      bins:                       # bins 定义
        - name: low_addr
          values: "{[0:0x0FFF]}"
        - name: high_addr
          values: "{[0xF000:0xFFFF]}"
      ignore_bins:                # 忽略 bins
        - name: reserved
          values: "{[0x1000:0x1FFF]}"
    - name: burst_cp
      expr: hburst
      transition_bins:            # 转换覆盖
        - name: burst_seq
          trans: "(0=>1=>2)"
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
   - 🆕 脚本会自动修正错误的环境变量

4. **YAML parsing error**
   - 检查 YAML 语法
   - 确认缩进正确
   - 使用 Schema 验证配置文件

5. **Configuration validation failed**
   - 检查必需配置项是否完整
   - 验证 Agent、Interface、Item 之间的关联性

6. **🆕 UVM_GEN_DIR 版本不匹配警告**
   - 脚本会自动修正为当前脚本目录
   - 如需避免警告，请正确设置环境变量：
     ```bash
     export UVM_GEN_DIR=/path/to/uvm_gen_v1.2
     ```

7. **🆕 Coverage bins 语法错误**
   - bins 值需要用花括号包裹
   - 正确格式: `values: "{9'b000000001}"`
   - 错误格式: `values: "9'b000000001"`

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

### v1.2.1 (2026-03-19)
- **🆕 环境变量自动修正** - 检测 `UVM_GEN_DIR` 版本不匹配时自动修正，防止模板版本错误
- **🆕 配置文件安全检查** - 路径存在性、文件类型、读权限、大小限制（最大10MB）
- **🆕 输出目录安全检查** - 禁止写入系统目录，验证父目录存在性和写权限
- **🐛 修复 Coverage bins 格式** - 二进制字面量需用花括号包裹 `{9'b000000001}`
- **🐛 修复 base_test.mako** - 使用 `agent_instances` 替代 `config['agents']`

### v1.2.0 (2026-03-18)
- **🆕 Agent 实例化** - 同一 Agent 类型支持多次实例化，避免代码冗余
- **🆕 Transaction Item 增强** - 添加 do_compare、do_pack/do_unpack、do_print、约束块支持
- **🆕 Coverage 增强** - 支持 bins、ignore_bins、illegal_bins、transition_bins
- **🆕 紧凑配置格式** - 支持简化的 YAML 配置，减少配置文件行数
- **🆕 紧凑信号格式** - `{ haddr: o32 }` 等价于 `output [31:0] haddr`
- **🆕 RTL 解析增强** - 支持参数化模块和参数化端口宽度
- **向后兼容** - 旧格式配置文件无需修改即可使用

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