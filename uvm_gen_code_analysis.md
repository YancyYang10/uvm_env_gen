# UVM Generator v1.2 代码解读文档

> 适用对象：希望理解 uvm_gen.py 脚本原理的验证工程师
> 阅读时间：约 30 分钟

---

## 一、工具概述

### 1.1 这个工具是干什么的？

简单来说：**你写一个 YAML 配置文件，工具自动帮你生成完整的 UVM 验证环境代码。**

```
┌─────────────┐      ┌─────────────┐      ┌─────────────────┐
│ config.yml  │ ───> │ uvm_gen.py  │ ───> │ UVM 验证环境    │
│ (配置文件)   │      │ (生成器)     │      │ (完整的SV代码)  │
└─────────────┘      └─────────────┘      └─────────────────┘
```

### 1.2 能生成哪些组件？

| 组件类型 | 生成文件 | 说明 |
|---------|---------|------|
| Interface | `xxx_if.sv` | 接口定义，连接 DUT 和验证环境 |
| Transaction Item | `xxx_item.sv` | 数据事务类，带约束、比较、打包方法 |
| Driver | `xxx_driver.sv` | 驱动信号到 DUT |
| Monitor | `xxx_monitor.sv` | 采样 DUT 信号 |
| Sequencer | `xxx_sequencer.sv` | 产生事务序列 |
| Agent | `xxx_agent.sv` | 封装 Driver/Monitor/Sequencer |
| Scoreboard | `xxx_scoreboard.sv` | 比对结果 |
| Coverage | `xxx_coverage.sv` | 功能覆盖率 |
| Environment | `xxx_env.sv` | 环境顶层 |
| Testbench | `tb_top.sv` | 测试台顶层 |
| Test Case | `tc_xxx.sv` | 测试用例 |

---

## 二、架构设计

### 2.1 整体架构图

```
┌────────────────────────────────────────────────────────────┐
│                      UVMGenerator 类                       │
├────────────────────────────────────────────────────────────┤
│  初始化阶段                                                 │
│  ├─ setup_logging()          设置日志系统                  │
│  ├─ _validate_environment()   检查环境变量                  │
│  ├─ load_config()            加载 YAML 配置                │
│  ├─ validate_config()        验证配置完整性                │
│  └─ validate_template_dir()  验证模板目录                  │
├────────────────────────────────────────────────────────────┤
│  配置解析阶段                                               │
│  ├─ _parse_agent_config()    解析 Agent 配置              │
│  ├─ _expand_compact_interfaces() 展开紧凑接口格式          │
│  └─ _infer_coverage_interface() 推断覆盖率接口             │
├────────────────────────────────────────────────────────────┤
│  代码生成阶段                                               │
│  ├─ generate_data_components() 生成 Interface 和 Item      │
│  ├─ generate_agents()          生成 Agent 组件             │
│  ├─ generate_common_components() 生成通用组件              │
│  ├─ generate_testbench()       生成测试台                  │
│  └─ generate_scripts()         生成仿真脚本                │
└────────────────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────────────────┐
│                    RTLParser 类                            │
│  解析 RTL 文件，提取端口信息用于 testbench 自动连接         │
└────────────────────────────────────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────────────────────────┐
│                    Mako 模板引擎                           │
│  读取 .mako 模板文件，渲染生成 SystemVerilog 代码          │
└────────────────────────────────────────────────────────────┘
```

### 2.2 数据流

```
config.yml                    rtl/xxx.v
    │                             │
    ▼                             ▼
┌─────────┐                 ┌──────────┐
│ YAML    │                 │ RTLParser│
│ Loader  │                 │          │
└────┬────┘                 └────┬─────┘
     │                           │
     ▼                           ▼
┌─────────────────────────────────────┐
│            context (字典)            │
│   config, agents, items, interfaces │
│   item_map, if_map, rtl_ports       │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│         templates/*.mako            │
│   agent.mako, item.mako, ...        │
└──────────────────┬──────────────────┘
                   │ render_template()
                   ▼
┌─────────────────────────────────────┐
│         output_dir/*.sv             │
│   完整的 UVM 验证环境                │
└─────────────────────────────────────┘
```

---

## 三、核心模块详解

### 3.1 UVMGenerator 类 - 初始化

```python
class UVMGenerator:
    def __init__(self, config_path, debug=False):
        # 1. 设置日志系统
        self.setup_logging(debug)

        # 2. 检查 UVM_GEN_DIR 环境变量
        self._validate_environment()

        # 3. 加载 YAML 配置文件
        self.config = self.load_config(config_path)

        # 4. 初始化核心数据结构
        self.output_dir = self.config.get("output_dir", "uvm_env")
        self.item_map = {}           # item 名称 -> item 配置
        self.if_map = {}             # interface 名称 -> interface 配置
        self.agent_def_map = {}      # agent 类型定义
        self.agent_instances = []    # agent 实例列表
```

**关键数据结构说明：**

| 变量名 | 类型 | 用途 |
|-------|------|------|
| `item_map` | `dict` | 通过 item 名称快速查找配置，如 `item_map["ahb_item"]` |
| `if_map` | `dict` | 通过 interface 名称快速查找配置 |
| `agent_def_map` | `dict` | Agent 类型定义（一个类型只生成一套代码）|
| `agent_instances` | `list` | Agent 实例列表（支持多实例）|

### 3.2 配置验证机制

脚本有多层验证确保配置正确：

```
┌─────────────────────────────────────────────────────┐
│ 第一层：路径安全检查                                  │
│   _validate_config_path()                           │
│   - 文件是否存在                                      │
│   - 是否为文件（非目录）                              │
│   - 扩展名检查 (.yml/.yaml)                         │
│   - 文件权限检查                                      │
│   - 文件大小限制 (最大 10MB)                         │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 第二层：Schema 验证                                   │
│   validate_schema()                                 │
│   - 必需字段检查                                      │
│   - 字段类型检查                                      │
│   - 枚举值检查 (active/passive, in/out)             │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 第三层：业务逻辑验证                                  │
│   validate_config()                                 │
│   - RTL 配置完整性                                   │
│   - Testbench 配置完整性                            │
│   - Agent 与 Interface/Item 关联验证                │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 第四层：输出目录安全检查                              │
│   _validate_output_dir()                            │
│   - 禁止写入系统目录 (/, /root, /etc 等)            │
│   - 父目录存在性和写权限检查                         │
│   - 目录名合法性检查                                  │
└─────────────────────────────────────────────────────┘
```

### 3.3 Agent 配置解析（支持新旧格式）

脚本支持两种 Agent 配置格式：

**旧格式（向后兼容）：**
```yaml
agents:
  - name: ahb_master
    mode: active
    type: in
    interface: ahb_if
    item: ahb_item
```

**新格式（推荐）：**
```yaml
agent_types:
  ahb_master:
    interface: ahb_if
    item: ahb_item
    mode: active

agents:
  ahb_master: [agt1, agt2(mode=passive)]
```

解析流程：

```python
def _parse_agent_config(self):
    if "agent_types" in self.config:
        # 新格式：类型定义 + 实例列表
        self._parse_agent_types()
        self._expand_compact_agents()
    elif "agents" in self.config:
        # 旧格式：自动迁移
        self._migrate_legacy_agents()
```

### 3.4 模板渲染核心

```python
def render_template(self, template_name, context, output_file):
    """
    template_name: 模板文件名，如 "agent.mako"
    context: 渲染上下文字典
    output_file: 输出文件路径
    """
    # 1. 读取模板文件
    tpl_path = os.path.join(self.template_dir, template_name)
    with open(tpl_path, 'r') as f:
        tpl = Template(f.read())

    # 2. 渲染模板
    code = tpl.render(**context)

    # 3. 写入输出文件
    output_path = os.path.join(self.output_dir, output_file)
    with open(output_path, "w") as out:
        out.write(code)
```

---

## 四、RTLParser 模块

### 4.1 功能说明

RTLParser 用于解析 RTL 顶层模块的端口定义，自动生成 testbench 中的 DUT 实例化代码。

### 4.2 解析流程

```python
class RTLParser:
    def parse(self):
        # 1. 读取 RTL 文件
        with open(self.file_path, 'r') as f:
            content = f.read()

        # 2. 找到模块定义位置
        module_pos = self._find_module(content)

        # 3. 提取端口列表（支持嵌套括号）
        ports_str = self._extract_port_list(content, module_pos)

        # 4. 正则匹配端口
        # 支持格式: input/output/inout [type] [signed] [width] name
        port_pattern = r'(input|output|inout)\s*(reg|wire|logic)?\s*(signed)?\s*(\[[^\]]+\])?\s*(\w+)'

        # 5. 返回端口列表
        return [{"name": ..., "direction": ..., "width": ...}, ...]
```

### 4.3 支持的 RTL 格式

```verilog
// 基本格式
module ahb2apb (
    input  hclk,
    input  hreset_n,
    output [31:0] haddr,
    input  [31:0] hrdata
);

// 参数化模块
module ahb2apb #(
    parameter DATA_WIDTH = 32
) (
    input  [DATA_WIDTH-1:0] hwdata,
    ...
);
```

---

## 五、Mako 模板语法

### 5.1 基本语法

```mako
## 注释：以 ## 开头

## 变量替换
${variable}

## 条件语句
% if condition:
    code_here
% endif

## 循环语句
% for item in items:
    ${item['name']}
% endfor
```

### 5.2 item.mako 模板解析

```systemverilog
`ifndef _${item['name'].upper()}_SV_
`define _${item['name'].upper()}_SV_

class ${item['name']} extends uvm_sequence_item;
    `uvm_object_utils(${item['name']})

    ## 遍历字段列表
    % for field in item['fields']:
    % if field['rand']:
    rand ${field['type']} ${field['name']};
    % else:
    ${field['type']} ${field['name']};
    % endif
    % endfor

    ## 约束块（可选）
    % if item.get('constraints'):
    % for c in item['constraints']:
    constraint ${c['name']} {
        ${c['expr']};
    }
    % endfor
    % endif

    // ... 其他方法
endclass

`endif
```

### 5.3 agent.mako 模板解析

关键点：根据实例名动态获取 is_active 配置

```systemverilog
// 根据实例名获取对应的 is_active 配置
case(get_name())
% for inst in agent_instances:
% if inst['type'] == agent['name']:
    "${inst['name']}_agt": is_active = cfg_m.${inst['name']}_agt_is_active;
% endif
% endfor
    default: is_active = UVM_PASSIVE;
endcase
```

---

## 六、配置文件详解

### 6.1 完整配置结构

```yaml
# ==================== 全局配置 ====================
output_dir: ./uvm_env          # 输出目录

# ==================== RTL 配置 ====================
rtl:
  top_file: "/path/to/rtl.v"   # RTL 顶层文件
  top_module: "module_name"    # 顶层模块名
  flist: "/path/to/rtl.f"      # 文件列表

# ==================== Testbench 配置 ====================
testbench:
  name: tb_top                 # testbench 名称
  timescale: "1ns/1ps"         # 时间单位
  dut_instance: "DUT"          # DUT 实例名

# ==================== Test 配置 ====================
test:
  base_name: tc_base_test      # 基础测试用例名
  sanity_name: tc_sanity       # 冒烟测试用例名

# ==================== Environment 配置 ====================
env:
  name: xxx_env
  has_coverage: true
  has_scoreboard: true
  has_ref_model: true

# ==================== Config 配置 ====================
cfg:
  name: top_cfg
  fields:
    - { name: is_active, type: int, rand: false }

# ==================== Items 配置 ====================
items:
  - name: ahb_item
    fields:
      - { name: addr, type: "logic[31:0]", rand: true }
    constraints:
      - { name: addr_c, expr: "addr inside {[0:'hFFFF]}" }

# ==================== Interfaces 配置 ====================
interfaces:
  - name: ahb_if
    clock: hclk
    reset: hreset_n
    signals:
      - { name: haddr, type: "logic[31:0]", dir: output }

# ==================== Agents 配置 ====================
agents:
  - name: ahb_master
    mode: active              # active | passive
    type: in                  # in | out
    interface: ahb_if
    item: ahb_item

# ==================== Scoreboard 配置 ====================
scoreboard:
  name: xxx_scoreboard
  actual_type: [apb_item]
  expected_type: [apb_item]

# ==================== Coverage 配置 ====================
coverage:
  name: xxx_coverage
  groups:
    - name: ahb_cov
      interface: [ahb_if, hclk, hreset_n]
      coverpoints:
        - name: addr_cp
          expr: "haddr"
          bins:
            - { name: low, values: "{[0:'h0FFF]}" }
```

### 6.2 紧凑格式支持

接口紧凑格式：
```yaml
interfaces:
  ahb_if:
    clock: hclk
    reset: hreset_n
    signals:
      haddr: o32      # output [31:0]
      hready: i       # input
      htrans: o2      # output [1:0]
```

信号格式解析：
- `o32` = output [31:0]
- `i8` = input [7:0]
- `o1` = output (单比特)
- `i` = input (单比特)

---

## 七、生成流程

### 7.1 generate() 主流程

```python
def generate(self):
    # 1. 安全检查
    self._validate_output_dir()

    # 2. 备份已存在的输出目录
    if os.path.exists(self.output_dir):
        backup_dir = f"{self.output_dir}_backup_xxx"
        shutil.copytree(self.output_dir, backup_dir)

    # 3. 创建输出目录
    os.makedirs(self.output_dir, exist_ok=True)

    # 4. 准备渲染上下文
    context = {
        "config": self.config,
        "agents": self.config.get("agents", []),
        "agent_types": self.agent_def_map,
        "agent_instances": self.agent_instances,
        ...
    }

    try:
        # 5. 生成各组件
        self.generate_data_components()    # Interface + Item
        self.generate_agents(context)       # Agent 组件
        self.generate_common_components(context)  # Scoreboard/Coverage等
        self.generate_testbench(context)    # Testbench
        self.generate_scripts()             # 仿真脚本

        # 6. 生成报告
        self.generate_report()

    except Exception as e:
        # 7. 失败回滚
        self.rollback(initial_files)
        raise
```

### 7.2 目录结构

生成的目录结构：

```
output_dir/
├── uvm_tb/
│   ├── interfaces/
│   │   └── xxx_if.sv
│   ├── items/
│   │   └── xxx_item.sv
│   ├── xxx_agent/
│   │   ├── xxx_driver.sv
│   │   ├── xxx_monitor.sv
│   │   ├── xxx_sequencer.sv
│   │   └── xxx_agent.sv
│   ├── top_cfg.sv
│   ├── virtual_sequencer.sv
│   ├── ref_model.sv
│   ├── scoreboard.sv
│   ├── coverage.sv
│   └── xxx_env.sv
├── uvm_tc/
│   ├── seq/
│   │   └── xxx_sequence.sv
│   ├── tc_base_test.sv
│   └── tc_sanity.sv
├── bench/
│   └── tb_top.sv
└── rsim/
    ├── Makefile
    ├── run.tcl
    ├── cm.cfg
    ├── rtl.f
    └── tb.f
```

---

## 八、使用示例

### 8.1 基本使用

```bash
# 设置环境变量
export UVM_GEN_DIR=/home/IC_verify/script/uvm_gen

# 运行生成器
python3 uvm_gen.py -c config.yml

# 调试模式
python3 uvm_gen.py -c config.yml -d
```

### 8.2 日志输出示例

```
2024-01-15 10:00:00 - __main__ - INFO - Loading configuration from: config.yml
2024-01-15 10:00:00 - __main__ - INFO - Configuration loaded successfully
2024-01-15 10:00:00 - __main__ - INFO - Template directory validated: /path/to/templates
2024-01-15 10:00:00 - __main__ - INFO - Output directory: ./uvm_env
2024-01-15 10:00:00 - __main__ - INFO - Starting UVM environment generation...
2024-01-15 10:00:00 - __main__ - INFO - Generating data components...
2024-01-15 10:00:00 - __main__ - INFO - Generated 2 interfaces and 2 items
2024-01-15 10:00:00 - __main__ - INFO - Generating agents...
2024-01-15 10:00:00 - __main__ - INFO - Successfully generated agent type: ahb_master
2024-01-15 10:00:00 - __main__ - INFO - Generation completed successfully!
```

---

## 九、常见问题

### Q1: 为什么需要 UVM_GEN_DIR 环境变量？

用于定位模板目录。脚本会自动检测并设置，无需手动配置。

### Q2: 如何添加自定义模板？

1. 在 `templates/` 目录添加 `.mako` 文件
2. 在 `generate_xxx()` 方法中添加渲染调用

### Q3: 生成的代码如何修改？

直接修改生成的 `.sv` 文件。重新运行生成器会自动备份原有文件。

### Q4: 如何支持新的接口类型？

在配置文件的 `interfaces` 部分添加新接口定义即可，无需修改代码。

---

## 十、扩展指南

### 10.1 添加新的模板类型

1. 创建模板文件 `templates/new_component.mako`
2. 在 `generate_common_components()` 中添加：

```python
common_templates.append(
    ('new_component.mako', 'uvm_tb/${config["new"]["name"]}.sv')
)
```

### 10.2 自定义字段类型

修改 `_validate_dict()` 方法添加新的类型验证。

---

## 附录：模板文件清单

| 模板文件 | 生成组件 | 说明 |
|---------|---------|------|
| `interface.mako` | Interface | 接口定义 |
| `item.mako` | Transaction Item | 事务类 |
| `driver.mako` | Driver | 驱动器 |
| `monitor.mako` | Monitor | 监视器 |
| `sequencer.mako` | Sequencer | 序列器 |
| `agent.mako` | Agent | 代理组件 |
| `sequence.mako` | Sequence | 序列 |
| `top_cfg.mako` | Config | 配置类 |
| `virtual_sequencer.mako` | Virtual Sequencer | 虚拟序列器 |
| `ref_model.mako` | Reference Model | 参考模型 |
| `scoreboard.mako` | Scoreboard | 记分板 |
| `coverage.mako` | Coverage | 覆盖率 |
| `env.mako` | Environment | 验证环境 |
| `testbench.mako` | Testbench | 测试台 |
| `base_test.mako` | Base Test | 基础测试 |
| `sanity_test.mako` | Sanity Test | 冒烟测试 |

---

*文档版本: v1.0*
*生成日期: 2026-03-23*