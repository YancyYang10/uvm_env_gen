# UVM Environment Generator (uvm_gen.py)

## 版本信息
- **版本**: v2.1.0
- **更新日期**: 2026-04-05
- **Python 版本**: 3.6+

## 简介

uvm_gen.py 是一个基于 YAML 配置文件的 UVM 测试台自动生成工具，能够从配置文件自动生成完整的 UVM 测试台结构。

## 安装

```bash
pip install mako pyyaml
export UVM_GEN_DIR=/path/to/uvm_gen
```

## 快速开始

```bash
python uvm_gen.py -c config.yml        # 生成验证环境
python uvm_gen.py -c config.yml -d      # 调试模式
```

---

# YAML 配置文件指南

## 配置结构

```yaml
output_dir: /path/to/output             # 输出目录

rtl:                                    # RTL 配置
  top_file: "/path/to/design.v"
  top_module: "my_design"
  flist: "/path/to/rtl.f"

testbench:                              # 测试台配置
  name: tb_top
  timescale: "1ns/1ps"
  dut_instance: "DUT"

test:                                   # 测试用例
  base_name: tc_base_test
  sanity_name: tc_sanity

env:                                    # UVM 环境
  name: chip_env
  has_coverage: true
  has_scoreboard: true
  has_ref_model: true

cfg:                                    # 配置对象
  name: top_cfg
  fields:
    - { name: scb_en, type: int, rand: false }
```

---

## Interface 配置

信号规格：`o` = output, `i` = input, 数字 = 位宽

```yaml
interfaces:
  ahb_master_if:                        # 命名与 agent 类型一致
    clock: hclk
    clk_period: 10ns
    reset: hreset_n
    signals:
      hsel: o1              # output logic hsel
      haddr: o32            # output logic[31:0] haddr
      hrdata: i32           # input logic[31:0] hrdata
```

---

## Transaction Item 配置

```yaml
items:
  - name: ahb_master_item              # 命名与 agent 类型一致
    fields:
      - { name: addr, type: "logic[31:0]", rand: true }
      - { name: data, type: "logic[31:0]", rand: true }
      - { name: write, type: logic, rand: true }
    constraints:
      - { name: addr_align_c, expr: "addr % 4 == 0" }
```

---

## Agent 配置

### 两步配置

```yaml
# Step 1: 定义 Agent 类型 (interface/item 命名与 agent 类型一致)
agent_types:
  ahb_master:
    interface: ahb_master_if           # 与 agent 类型名一致
    item: ahb_master_item              # 与 agent 类型名一致
    mode: active                       # active/passive

  apb_slave:
    interface: apb_slave_if
    item: apb_slave_item
    mode: active

# Step 2: 实例化 Agent
agents:
  ahb_master: [ahb_mst]
  apb_slave: [apb_slv0, apb_slv1, apb_slv2]
```

### 命名规范 (v2.1.0)

| 组件 | 用户填写 | 脚本生成 |
|------|----------|----------|
| Agent 类型 | `ahb_master` | - |
| Interface 文件 | `ahb_master_if` | `ahb_master_if.sv` |
| Item 文件 | `ahb_master_item` | `ahb_master_item.sv` |
| Agent 实例 | `ahb_mst` | `ahb_mst_agt_m` |
| Interface vif | - | `ahb_mst_vif` |
| Sequencer handle | - | `ahb_mst_sqr` |
| Config 字段 | - | `ahb_mst_agt_m_is_active` |

### 其他组件固定命名

| 组件 | 实例名 |
|------|--------|
| Reference Model | `rm_m` |
| Scoreboard | `scb_m` |
| Coverage | `cov_m` |
| Virtual Sequencer | `vsqr_m` |
| Config | `cfg_m` |

### type_role 配置 (用于 TLM 连接)

```yaml
agents:
  ahb_master: [ahb_mst]                           # 默认无 role
  apb_slave: [apb_slv0(type_role=out), apb_slv1(type_role=out)]
```

- `type_role: in` - 连接到 Ref Model 输入
- `type_role: out` - 连接到 Scoreboard actual 端口

---

## Reference Model

```yaml
ref_model:
  name: ahb2apb_ref_model
  input_item: [ahb_master_item]       # 输入 item 类型
  predicted_type: [apb_slave_item]    # 输出 item 类型
```

---

## Scoreboard

```yaml
scoreboard:
  name: ahb2apb_scoreboard
  actual_type: [apb_slave_item]        # 实际输出 item 类型
  expected_type: [apb_slave_item]      # 预期 item 类型
  compare_method: "full_compare"       # 比对方法
```

---

## Coverage

```yaml
coverage:
  name: ahb2apb_coverage
  groups:
    - name: ahb_cov
      interface: [ahb_master_if, hclk, hreset_n]
      coverpoints:
        - name: addr_cp
          expr: "haddr"
          bins:
            - { name: low, values: "{[0:'h0FFF]}" }
            - { name: high, values: "{['h1000:$]}" }
        - name: write_cp
          expr: "hwrite"
          bins:
            - { name: read, values: "{0}" }
            - { name: write, values: "{1}" }
      crosses:
        - name: addr_x_write
          points: [addr_cp, write_cp]
```

---

## 生成文件结构

```
output_dir/
├── uvm_tb/
│   ├── ahb_master_agent/           # Agent 目录 (包含 interface 和 item)
│   │   ├── ahb_master_if.sv        # Interface 在 agent 目录内
│   │   ├── ahb_master_item.sv      # Item 在 agent 目录内
│   │   ├── ahb_master_agent.sv
│   │   ├── ahb_master_driver.sv
│   │   ├── ahb_master_monitor.sv
│   │   └── ahb_master_sequencer.sv
│   ├── apb_slave_agent/
│   │   ├── apb_slave_if.sv
│   │   ├── apb_slave_item.sv
│   │   └── ...
│   ├── top_cfg.sv                  # 配置类 (含 drv_idle_enum)
│   ├── virtual_sequencer.sv
│   ├── *_ref_model.sv
│   ├── *_scoreboard.sv
│   ├── *_coverage.sv
│   └── *_env.sv
├── uvm_tc/
│   ├── seq/
│   ├── tc_base_test.sv
│   └── tc_sanity.sv
├── bench/
│   └── tb_top.sv
└── rsim/
    ├── Makefile
    └── cm.cfg
```

---

## 核心增强功能 (v2.1.0)

### 1. Driver 增强

- **drv_idle_enum**: 全局配置 IDLE 模式
  ```systemverilog
  typedef enum bit [1:0] {
      DRV_IDLE_LAST = 2'b00,  // 保持最后一次驱动值
      DRV_IDLE_0    = 2'b01,  // 驱动 0 值
      DRV_IDLE_X    = 2'b10   // 驱动 X 值（释放总线）
  } drv_idle_enum;
  ```

- **drv_cb 非阻塞赋值**: 使用 `vif.drv_cb.signal <= value`
- **`*_last` 变量**: 保存最后驱动值用于 `DRV_IDLE_LAST` 模式
- **复位处理**: `reset_task()` 和 `init_signals()`

### 2. Monitor 增强

- **mon_cb 采样**: 使用 `vif.mon_cb.signal` 采样
- **复位等待**: `wait(vif.reset_n)` 后开始采样
- **null check**: 仅发送有效交易

### 3. Scoreboard 增强 (杜绝假 PASS)

- **独立队列**: 每个 output item 独立的 `expected_q` 和 `actual_q`
- **独立比对**: 每个 output item 独立的 `compare_task()`
- **统计报告**: 每个 output item 独立的 `total/passed/failed` 计数
- **数量检查**: `report_phase` 检查队列是否清空
- **完整比对**: 使用 `do_compare()` 比对所有字段

### 4. Env TLM 连接

- 分离 `INPUT` / `OUTPUT` agent 连接
- 每个 out_agent 独立连接到 scoreboard
- TLM 连接日志输出

---

## 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `interfaces must be a dict` | 使用了旧格式 | 改为字典格式 |
| `Missing agent_types` | 缺少类型定义 | 添加 agent_types |
| `Interface not found` | 引用不存在 | 检查拼写 |
| Coverage bins 语法错误 | 格式不正确 | 用花括号包裹 |

---

## 更新日志

### v2.1.0 (2026-04-05)
- **目录结构优化**: interface 和 item 放到各自 agent 目录下
- **命名规范**: interface/item 命名与 agent 类型一致 (如 `ahb_master_if`, `ahb_master_item`)
- **Driver 增强**: drv_idle_enum, drv_cb 非阻塞赋值, `*_last` 变量, 复位处理
- **Monitor 增强**: mon_cb 采样, 复位等待, null check
- **Scoreboard 增强**: 独立队列/比对/统计, 杜绝假 PASS
- **Env 增强**: TLM 连接日志, INPUT/OUTPUT agent 分离连接
- **配置增强**: 支持 `type_role=out` 参数标记输出 agent

### v2.0.0 (2026-04-04)
- 移除旧格式支持，只支持紧凑格式
- 统一命名规则：`xxx_agt_m`, `xxx_vif`, `xxx_sqr`
- 固定组件命名：`rm_m`, `scb_m`, `cov_m`, `vsqr_m`

## 许可证

MIT License