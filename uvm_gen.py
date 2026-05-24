#!/usr/bin/python3
from mako.template import Template
import os
import yaml
import argparse
import logging
import sys
from rtl_parser import RTLParser

# 获取脚本所在目录（用于环境变量校验）
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

class UVMGenerator:
    def __init__(self, config_path, debug=False):
        # 设置日志系统
        self.setup_logging(debug)
        self.logger = logging.getLogger(__name__)
        self.verilog_files = []

        # 检查并验证 UVM_GEN_DIR 环境变量
        self._validate_environment()

        # 设置模板目录
        self.template_dir = str(os.getenv('UVM_GEN_DIR', ""))+"/templates"

        # 加载配置（带安全检查）
        self.config = self.load_config(config_path)

        # 初始化变量
        self.output_dir = self.config.get("output_dir", "uvm_env")
        self.item_map = {}
        self.if_map = {}
        self.agent_def_map = {}      # Agent 类型定义
        self.agent_instances = []    # Agent 实例列表

        # 映射配置
        if "items" in self.config:
            self.item_map = {item["name"]: item for item in self.config["items"]}
        if "interfaces" in self.config:
            # 支持紧凑格式的 interfaces
            self._expand_compact_interfaces()

        # 解析 Agent 配置 (支持新格式和旧格式)
        self._parse_agent_config()

        # 推断 coverage interface (支持简化格式)
        self._infer_coverage_interface()

        # 验证配置
        self.validate_config()

        # 验证模板目录
        self.validate_template_dir()

        # 输出信息
        self.logger.info(f"Output directory: {self.output_dir}")
        self.logger.debug(f"Template directory: {self.template_dir}")
        if "interfaces" in self.config and self.config["interfaces"]:
            self.logger.debug(f"Example interface clock: {self.if_map['apb_if']['clock']}")

    def setup_logging(self, debug=False):
        """设置日志系统"""
        log_level = logging.DEBUG if debug else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler('uvm_gen.log')
            ]
        )

    def _validate_environment(self):
        """验证 UVM_GEN_DIR 环境变量设置正确"""
        uvm_gen_dir = os.getenv('UVM_GEN_DIR', '')

        # 检查环境变量是否设置
        if not uvm_gen_dir:
            self.logger.info(
                "UVM_GEN_DIR environment variable not set. "
                f"Auto-setting to script directory: {_SCRIPT_DIR}"
            )
            os.environ['UVM_GEN_DIR'] = _SCRIPT_DIR
            return

        # 检查环境变量指向的目录是否存在
        if not os.path.exists(uvm_gen_dir):
            self.logger.warning(
                f"UVM_GEN_DIR points to non-existent directory: {uvm_gen_dir}. "
                f"Falling back to script directory: {_SCRIPT_DIR}"
            )
            os.environ['UVM_GEN_DIR'] = _SCRIPT_DIR
            return

        # 检查 templates 子目录是否存在
        templates_dir = os.path.join(uvm_gen_dir, 'templates')
        if not os.path.exists(templates_dir):
            self.logger.warning(
                f"Templates directory not found in UVM_GEN_DIR: {templates_dir}. "
                f"Falling back to script directory: {_SCRIPT_DIR}"
            )
            os.environ['UVM_GEN_DIR'] = _SCRIPT_DIR
            return

        # 环境变量与脚本目录不匹配时自动修正
        if os.path.normpath(uvm_gen_dir) != os.path.normpath(_SCRIPT_DIR):
            self.logger.warning(
                f"UVM_GEN_DIR ({uvm_gen_dir}) does not match script directory ({_SCRIPT_DIR}). "
                f"Auto-correcting to script directory to prevent template version mismatch."
            )
            os.environ['UVM_GEN_DIR'] = _SCRIPT_DIR
            return

        self.logger.debug(f"UVM_GEN_DIR validated: {uvm_gen_dir}")

    def load_config(self, config_path):
        """加载并验证配置文件"""
        self.logger.info(f"Loading configuration from: {config_path}")

        # 安全检查：配置文件路径
        self._validate_config_path(config_path)

        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)

            if not config:
                raise ValueError("Configuration file is empty")

            # 验证必需的配置项
            self.logger.debug("Validating required configuration sections")
            required_sections = ['output_dir', 'rtl', 'testbench', 'test']
            for section in required_sections:
                if section not in config:
                    raise ValueError(f"Missing required section: {section}")

            # 进行schema验证
            self.validate_schema(config)

            self.logger.info("Configuration loaded successfully")
            return config

        except FileNotFoundError:
            raise ValueError(f"Configuration file not found: {config_path}")
        except yaml.YAMLError as e:
            raise ValueError(f"YAML parsing error: {str(e)}")
        except Exception as e:
            raise ValueError(f"Error loading configuration: {str(e)}")

    def _validate_config_path(self, config_path):
        """验证配置文件路径安全性"""
        # 检查路径是否存在
        if not os.path.exists(config_path):
            raise ValueError(f"Configuration file not found: {config_path}")

        # 检查是否为文件（而非目录）
        if not os.path.isfile(config_path):
            raise ValueError(f"Configuration path is not a file: {config_path}")

        # 检查文件扩展名
        if not config_path.endswith(('.yml', '.yaml')):
            self.logger.warning(
                f"Configuration file does not have .yml/.yaml extension: {config_path}"
            )

        # 检查文件权限（可读）
        if not os.access(config_path, os.R_OK):
            raise ValueError(f"Configuration file not readable: {config_path}")

        # 检查文件大小（防止加载超大文件）
        file_size = os.path.getsize(config_path)
        max_size = 10 * 1024 * 1024  # 10MB
        if file_size > max_size:
            raise ValueError(
                f"Configuration file too large ({file_size} bytes). "
                f"Maximum allowed: {max_size} bytes"
            )

        self.logger.debug(f"Config file validated: {config_path} ({file_size} bytes)")

    def _validate_output_dir(self):
        """验证输出目录安全性"""
        output_dir = self.output_dir

        # 解析为绝对路径
        abs_output_dir = os.path.abspath(output_dir)

        # 危险目录列表（不允许作为输出目录）
        dangerous_dirs = [
            '/', '/root', '/home', '/etc', '/usr', '/var', '/bin', '/sbin',
            '/lib', '/lib64', '/boot', '/dev', '/proc', '/sys'
        ]

        for dangerous_dir in dangerous_dirs:
            if os.path.normpath(abs_output_dir) == os.path.normpath(dangerous_dir):
                raise ValueError(
                    f"Output directory cannot be a system directory: {output_dir}"
                )

        # 检查输出目录是否在脚本目录内（可选警告）
        if abs_output_dir.startswith(_SCRIPT_DIR):
            self.logger.warning(
                f"Output directory is inside script directory. "
                f"This may cause issues with version control."
            )

        # 检查父目录是否存在且可写
        parent_dir = os.path.dirname(abs_output_dir)
        if os.path.exists(parent_dir):
            if not os.access(parent_dir, os.W_OK):
                raise ValueError(
                    f"Parent directory not writable: {parent_dir}"
                )
        else:
            raise ValueError(
                f"Parent directory does not exist: {parent_dir}"
            )

        # 检查输出目录名称是否合法
        dir_name = os.path.basename(abs_output_dir)
        if not dir_name or dir_name.startswith('.') or '..' in dir_name:
            raise ValueError(
                f"Invalid output directory name: {dir_name}"
            )

        self.logger.debug(f"Output directory validated: {abs_output_dir}")

    def validate_config(self):
        """验证配置文件内容"""
        self.logger.info("Validating configuration content")

        # 验证rtl配置
        rtl_config = self.config.get('rtl', {})
        required_rtl = ['top_file', 'top_module', 'flist']
        for key in required_rtl:
            if key not in rtl_config:
                raise ValueError(f"Missing required RTL configuration: {key}")

        # 验证文件存在性
        for file_path in [rtl_config['top_file'], rtl_config['flist']]:
            if not os.path.exists(file_path):
                self.logger.warning(f"File not found: {file_path}")

        # 验证testbench配置
        tb_config = self.config.get('testbench', {})
        required_tb = ['name', 'timescale', 'dut_instance']
        for key in required_tb:
            if key not in tb_config:
                raise ValueError(f"Missing required testbench configuration: {key}")

        # 验证agents配置
        if 'agents' not in self.config:
            raise ValueError("Missing 'agents' configuration")

        for agent in self.config['agents']:
            required_agent = ['name', 'mode', 'type', 'interface', 'item']
            for key in required_agent:
                if key not in agent:
                    raise ValueError(f"Missing required agent field: {key}")

            # 验证关联的接口和item
            if agent['interface'] not in self.if_map:
                raise ValueError(f"Interface '{agent['interface']}' not found in interfaces")
            if agent['item'] not in self.item_map:
                raise ValueError(f"Item '{agent['item']}' not found in items")

        self.logger.info("Configuration validation passed")

    def validate_schema(self, config):
        """验证配置文件schema"""
        schema = {
            'output_dir': {'type': str, 'required': True},
            'rtl': {
                'type': dict,
                'required': True,
                'fields': {
                    'top_file': {'type': str, 'required': True},
                    'top_module': {'type': str, 'required': True},
                    'flist': {'type': str, 'required': True}
                }
            },
            'testbench': {
                'type': dict,
                'required': True,
                'fields': {
                    'name': {'type': str, 'required': True},
                    'timescale': {'type': str, 'required': True},
                    'dut_instance': {'type': str, 'required': True}
                }
            },
            'test': {
                'type': dict,
                'required': True,
                'fields': {
                    'base_name': {'type': str, 'required': True},
                    'sanity_name': {'type': str, 'required': True}
                }
            },
            'agents': {
                'type': list,
                'required': True,
                'item_schema': {
                    'name': {'type': str, 'required': True},
                    'mode': {'type': str, 'required': True, 'enum': ['active', 'passive']},
                    'type': {'type': str, 'required': True, 'enum': ['in', 'out']},
                    'interface': {'type': str, 'required': True},
                    'item': {'type': str, 'required': True}
                }
            }
        }

        self._validate_dict(config, schema, "root")

    def _validate_dict(self, data, schema, path):
        """递归验证字典"""
        # 验证必需字段
        if 'required' in schema and schema['required']:
            if data is None:
                raise ValueError(f"Required section missing at {path}")

            if 'fields' in schema:
                for field, field_schema in schema['fields'].items():
                    if field not in data:
                        raise ValueError(f"Missing required field '{field}' at {path}")

                    self._validate_value(data[field], field_schema, f"{path}.{field}")

        # 验证列表项
        if schema.get('type') == list and 'item_schema' in schema:
            if not isinstance(data, list):
                raise ValueError(f"Expected list at {path}")

            for i, item in enumerate(data):
                self._validate_dict(item, schema['item_schema'], f"{path}[{i}]")

    def _validate_value(self, value, schema, path):
        """验证单个值"""
        if schema.get('type') and not isinstance(value, schema['type']):
            raise ValueError(f"Expected {schema['type']} at {path}, got {type(value)}")

        if 'enum' in schema and value not in schema['enum']:
            raise ValueError(f"Invalid value '{value}' at {path}. Expected one of: {schema['enum']}")

    def validate_template_dir(self):
        """验证模板目录"""
        if not self.template_dir or not os.path.exists(self.template_dir):
            raise ValueError(
                f"Template directory not found: {self.template_dir}. "
                f"Please set UVM_GEN_DIR environment variable or check templates directory"
            )
        self.logger.info(f"Template directory validated: {self.template_dir}")

    def _parse_agent_config(self):
        """解析 Agent 配置，支持新格式(agent_types/agent_instances)和旧格式(agents)"""
        import re

        # 新格式: agent_types + agent_instances
        if "agent_types" in self.config:
            self.logger.info("Using new agent format (agent_types + agent_instances)")

            # 解析 agent_types (支持列表和字典两种格式)
            agent_types = self.config["agent_types"]
            if isinstance(agent_types, list):
                self.agent_def_map = {a["name"]: a for a in agent_types}
            else:
                # 字典格式: { type_name: { interface: ..., item: ... } }
                for type_name, attrs in agent_types.items():
                    self.agent_def_map[type_name] = {
                        "name": type_name,
                        "interface": attrs.get("interface"),
                        "item": attrs.get("item"),
                        "mode": attrs.get("mode", "active")
                    }

            # 解析 agent_instances 或紧凑格式的 agents
            if "agent_instances" in self.config:
                self.agent_instances = self.config["agent_instances"]
            elif "agents" in self.config:
                # 紧凑格式: { type_name: [inst1, inst2, ...] }
                self.agent_instances = self._expand_compact_agents()

        # 旧格式: agents (向后兼容)
        elif "agents" in self.config:
            self.logger.info("Using legacy agent format (auto-migrating to new format)")
            self._migrate_legacy_agents()

        self.logger.info(f"Parsed {len(self.agent_def_map)} agent types, {len(self.agent_instances)} instances")

    def _expand_compact_agents(self):
        """展开紧凑格式的 agents: { type_name: [inst1, inst2(mode=passive)] }"""
        import re
        instances = []

        agents_config = self.config.get("agents", {})
        for type_name, inst_list in agents_config.items():
            type_def = self.agent_def_map.get(type_name, {})
            default_mode = type_def.get("mode", "active")

            for inst_def in inst_list:
                # 解析 "inst_name" 或 "inst_name(mode=passive)"
                if isinstance(inst_def, str):
                    match = re.match(r'(\w+)(?:\(mode=(\w+)\))?', inst_def)
                    name = match.group(1)
                    mode = match.group(2) or default_mode
                elif isinstance(inst_def, dict):
                    name = inst_def.get("name")
                    mode = inst_def.get("mode", default_mode)
                else:
                    continue

                instances.append({
                    "type": type_name,
                    "name": name,
                    "mode": mode,
                    "interface": type_def.get("interface"),
                    "item": type_def.get("item")
                })

        return instances

    def _migrate_legacy_agents(self):
        """向后兼容: 将旧格式 agents 转换为新格式"""
        legacy = self.config["agents"]
        seen_types = {}

        for agent in legacy:
            # 创建唯一类型标识
            type_key = f"{agent['interface']}_{agent['item']}_{agent['mode']}"

            if type_key not in seen_types:
                # 去掉 _if 后缀，模板路径会追加 _agent
                type_name = agent['interface'].replace('_if', '')
                seen_types[type_key] = type_name
                self.agent_def_map[type_name] = {
                    "name": type_name,
                    "mode": agent["mode"],
                    "interface": agent["interface"],
                    "item": agent["item"]
                }

            # 创建实例
            self.agent_instances.append({
                "type": seen_types[type_key],
                "name": agent["name"],
                "mode": agent["mode"],
                "interface": agent["interface"],
                "item": agent["item"],
                "type_role": agent.get("type", "in")
            })

    def _parse_compact_signals(self, signals_dict):
        """解析紧凑信号格式: { name: 'o32' } -> { name, type, dir }
           o32 = output [31:0], i8 = input [7:0], o1 = output, i = input
        """
        result = []
        for name, spec in signals_dict.items():
            spec = str(spec).strip()
            # 判断方向
            if spec.startswith('o'):
                direction = 'output'
            elif spec.startswith('i'):
                direction = 'input'
            else:
                direction = 'output'  # 默认

            # 解析位宽
            width_str = spec[1:] if len(spec) > 1 else '1'
            try:
                width = int(width_str)
                if width > 1:
                    type_str = f"logic[{width-1}:0]"
                else:
                    type_str = "logic"
            except ValueError:
                type_str = "logic"

            result.append({
                'name': name,
                'dir': direction,
                'type': type_str
            })
        return result

    def _expand_compact_interfaces(self):
        """展开紧凑格式的 interfaces"""
        if "interfaces" not in self.config:
            return

        interfaces = self.config["interfaces"]
        expanded = []

        # 支持两种格式：列表（旧格式）和字典（紧凑格式）
        if isinstance(interfaces, list):
            # 旧格式列表，直接使用
            self.if_map = {intf["name"]: intf for intf in interfaces}
            return

        # 字典格式（紧凑格式）
        for if_name, if_def in interfaces.items():
            if isinstance(if_def, dict):
                # 检查是否为紧凑格式
                if "signals" in if_def and isinstance(if_def["signals"], dict):
                    # 紧凑格式，需要展开
                    expanded_if = {
                        "name": if_name,
                        "clock": if_def.get("clock"),
                        "reset": if_def.get("reset"),
                        "clk_period": if_def.get("clk_period", "10ns"),
                        "signals": self._parse_compact_signals(if_def["signals"])
                    }
                    expanded.append(expanded_if)
                else:
                    # 标准格式
                    if_def["name"] = if_name
                    expanded.append(if_def)

        # 更新配置
        self.config["interfaces"] = expanded
        self.if_map = {intf["name"]: intf for intf in expanded}

    def _infer_coverage_interface(self):
        """从 interface 定义推断 coverage 的 clock/reset"""
        if "coverage" not in self.config:
            return

        coverage = self.config["coverage"]

        # 处理简化格式: { interface_name: [coverpoints] }
        if "groups" not in coverage:
            groups = []
            for if_name, coverpoints in coverage.items():
                if if_name in ["name"]:  # 跳过非 interface 键
                    continue
                if if_name in self.if_map:
                    intf = self.if_map[if_name]
                    group = {
                        "name": f"{if_name}_cov",
                        "interface": [if_name, intf.get("clock", "clk"), intf.get("reset", "rst_n")],
                        "coverpoints": coverpoints
                    }
                    groups.append(group)
            coverage["groups"] = groups

    def render_template(self, template_name, context, output_file):
        """渲染模板并输出文件"""
        try:
            tpl_path = os.path.join(self.template_dir, template_name)
            self.logger.debug(f"Rendering template: {template_name}")
            self.logger.debug(f"Template path: {tpl_path}")

            # 检查模板文件是否存在
            if not os.path.exists(tpl_path):
                raise FileNotFoundError(f"Template not found: {template_name}")

            with open(tpl_path, 'r') as f:
                tpl = Template(f.read())
                code = tpl.render(**context)

                output_path = os.path.join(self.output_dir, output_file)
                os.makedirs(os.path.dirname(output_path), exist_ok=True)

                with open(output_path, "w") as out:
                    out.write(code)

                self.logger.info(f"Generated: {output_file}")
                self.verilog_files.append(output_file)

        except FileNotFoundError as e:
            raise ValueError(f"Template file error: {str(e)}")
        except Exception as e:
            raise ValueError(f"Error rendering template {template_name}: {str(e)}")

    def generate_agents(self, context):
        """生成所有Agent组件 (只生成一套代码，支持多实例)"""
        self.logger.info("Generating agents...")
        agent_templates = [
            ('driver.mako', 'uvm_tb/${name}_agent/${name}_driver.sv'),
            ('monitor.mako', 'uvm_tb/${name}_agent/${name}_monitor.sv'),
            ('sequencer.mako', 'uvm_tb/${name}_agent/${name}_sequencer.sv'),
            ('agent.mako', 'uvm_tb/${name}_agent/${name}_agent.sv'),
            ('sequence.mako', 'uvm_tc/seq/${name}_sequence.sv')
        ]

        # 遍历 agent 类型定义 (只生成一套代码)
        for type_name, agent_def in self.agent_def_map.items():
            try:
                self.logger.debug(f"Generating agent type: {type_name}")

                item_name = agent_def["item"]
                if_name = agent_def["interface"]

                ctx = {
                    "agent": agent_def,
                    "item": self.item_map[item_name],
                    "item_name": item_name,
                    "intf": self.if_map[if_name],
                    "if_name": if_name,
                    **context
                }

                for tpl, pattern in agent_templates:
                    try:
                        output_file = Template(pattern).render(name=type_name)
                        self.render_template(tpl, ctx, output_file)
                    except Exception as e:
                        self.logger.error(f"Failed to generate {type_name} {tpl}: {str(e)}")
                        raise

                self.logger.info(f"Successfully generated agent type: {type_name}")

            except Exception as e:
                self.logger.error(f"Error generating agent: {str(e)}")
                raise

    def generate_common_components(self, context):
        """生成通用组件"""
        self.logger.info("Generating common components...")

        # 验证必需的配置项
        required_configs = ['cfg', 'ref_model', 'scoreboard', 'coverage', 'env', 'test']
        for cfg_name in required_configs:
            if cfg_name not in self.config:
                raise ValueError(f"Missing required configuration: {cfg_name}")

        common_templates = [
            ('top_cfg.mako', 'uvm_tb/${config["cfg"]["name"]}.sv'),
            ('virtual_sequencer.mako', 'uvm_tb/virtual_sequencer.sv'),
            ('ref_model.mako', 'uvm_tb/${config["ref_model"]["name"]}.sv'),
            ('scoreboard.mako', 'uvm_tb/${config["scoreboard"]["name"]}.sv'),
            ('coverage.mako', 'uvm_tb/${config["coverage"]["name"]}.sv'),
            ('env.mako', 'uvm_tb/${config["env"]["name"]}.sv'),
            ('base_test.mako', 'uvm_tc/${config["test"]["base_name"]}.sv'),
            ('sanity_test.mako', 'uvm_tc/${config["test"]["sanity_name"]}.sv')
        ]

        for tpl, output_pattern in common_templates:
            try:
                output_file = Template(output_pattern).render(config=self.config)
                self.render_template(tpl, context, output_file)
                # render_template 已经添加到 verilog_files，无需重复添加

            except Exception as e:
                self.logger.error(f"Failed to generate {tpl}: {str(e)}")
                raise

    def generate_testbench(self, context):
        """生成测试台顶层文件"""
        self.logger.info("Generating testbench...")

        rtl_ports = []
        if 'top_file' in self.config['rtl'] and 'top_module' in self.config['rtl']:
            try:
                self.logger.info("Parsing RTL ports...")
                parser = RTLParser(
                    self.config['rtl']['top_file'],
                    self.config['rtl']['top_module']
                )

                rtl_ports = parser.parse()
                self.logger.info(f"Parsed {len(rtl_ports)} ports from RTL")

                # 记录端口信息用于调试
                for port in rtl_ports[:5]:  # 只记录前5个端口避免日志过长
                    self.logger.debug(f"Port: {port['name']} ({port['direction']}) {port.get('width', '')}")

            except Exception as e:
                self.logger.warning(f"RTL parse warning: {str(e)}")
                self.logger.warning("DUT ports may be incorrect")

        context['rtl_ports'] = [{
            "name": port['name'],
            "direction": port['direction'],
            "width": port.get('width', '')
        } for port in rtl_ports]

        try:
            output_file = f"bench/{self.config['testbench']['name']}.sv"
            self.render_template('testbench.mako', context, output_file)
        except Exception as e:
            self.logger.error(f"Failed to generate testbench: {str(e)}")
            raise

    def generate_data_components(self):
        """生成数据组件（接口和Transaction Items）"""
        self.logger.info("Generating data components...")

        # 验证必需的配置
        if "interfaces" not in self.config:
            self.logger.warning("No interfaces configuration found")
            return

        if "items" not in self.config:
            self.logger.warning("No items configuration found")
            return

        # 生成接口
        self.logger.info("Generating interfaces...")
        for interface in self.config["interfaces"]:
            try:
                interface_name = interface["name"]
                self.logger.debug(f"Generating interface: {interface_name}")

                output_pattern = f'uvm_tb/interfaces/{interface["name"]}.sv'
                output_file = Template(output_pattern).render(config=self.config)
                self.render_template('interface.mako', {"interface": interface}, output_file)

            except Exception as e:
                self.logger.error(f"Failed to generate interface {interface.get('name', 'unknown')}: {str(e)}")
                raise

        # 生成Transaction Items
        self.logger.info("Generating transaction items...")
        for item in self.config["items"]:
            try:
                item_name = item["name"]
                self.logger.debug(f"Generating item: {item_name}")

                output_pattern = f'uvm_tb/items/{item["name"]}.sv'
                output_file = Template(output_pattern).render(config=self.config)
                self.render_template('item.mako', {"item": item}, output_file)

            except Exception as e:
                self.logger.error(f"Failed to generate item {item.get('name', 'unknown')}: {str(e)}")
                raise

        self.logger.info(f"Generated {len(self.config['interfaces'])} interfaces and {len(self.config['items'])} items")

    def generate_scripts(self):
        """生成仿真脚本"""
        self.logger.info("Generating simulation scripts...")

        rsim_dir = os.path.join(self.output_dir, "rsim")
        os.makedirs(rsim_dir, exist_ok=True)

        # 复制模板文件
        try:
            template_files = ["Makefile", "run.tcl", "cm.cfg"]
            for filename in template_files:
                src = os.path.join(self.template_dir, filename)
                dst = os.path.join(rsim_dir, filename)

                if os.path.exists(src):
                    import shutil
                    shutil.copy2(src, dst)
                    self.logger.debug(f"Copied: {filename}")
                else:
                    self.logger.warning(f"Template file not found: {filename}")

            # 复制文件列表
            flist_src = self.config['rtl']['flist']
            if os.path.exists(flist_src):
                flist_dst = os.path.join(rsim_dir, os.path.basename(flist_src))
                shutil.copy2(flist_src, flist_dst)
                self.logger.info(f"Copied file list: {os.path.basename(flist_src)}")
            else:
                raise FileNotFoundError(f"File list not found: {flist_src}")

        except Exception as e:
            self.logger.error(f"Error copying template files: {str(e)}")
            raise

        # 生成tb.f文件
        try:
            tb_path = os.path.join(rsim_dir, "tb.f")
            # 去重并保持顺序
            seen = set()
            unique_files = []
            top_cfg_file = None
            for sv_file in self.verilog_files:
                if sv_file not in seen:
                    seen.add(sv_file)
                    # 检查是否为 top_cfg
                    if 'top_cfg' in sv_file or sv_file.endswith('top_cfg.sv'):
                        top_cfg_file = sv_file
                    else:
                        unique_files.append(sv_file)
            # top_cfg 放在最前面
            if top_cfg_file:
                unique_files.insert(0, top_cfg_file)

            with open(tb_path, "w") as flist_file:
                for sv_file in unique_files:
                    flist_file.write(f"../{sv_file}\n")
            self.logger.info("Generated tb.f")
        except Exception as e:
            self.logger.error(f"Error generating tb.f: {str(e)}")
            raise

    def rollback(self, initial_files):
        """回滚已生成的文件"""
        self.logger.warning("Performing rollback...")

        current_files = set(os.listdir(self.output_dir))
        new_files = current_files - initial_files

        for file in new_files:
            try:
                file_path = os.path.join(self.output_dir, file)
                if os.path.isfile(file_path):
                    os.remove(file_path)
                    self.logger.debug(f"Deleted: {file}")
                elif os.path.isdir(file_path):
                    import shutil
                    shutil.rmtree(file_path)
                    self.logger.debug(f"Deleted directory: {file}")
            except Exception as e:
                self.logger.error(f"Failed to delete {file}: {str(e)}")

    def generate_report(self):
        """生成生成报告"""
        print("\n" + "="*60)
        print("UVM Environment Generation Report")
        print("="*60)
        print(f"Output directory: {self.output_dir}")
        print(f"Total files generated: {len(self.verilog_files)}")

        # 统计文件类型
        components = {
            "interfaces": 0,
            "items": 0,
            "agents": 0,
            "common": 0,
            "scripts": 0
        }

        for file in self.verilog_files:
            if "interfaces" in file:
                components["interfaces"] += 1
            elif "items" in file:
                components["items"] += 1
            elif "_agent/" in file:
                components["agents"] += 1
            elif file.endswith((".sv", ".v")):
                components["common"] += 1
            else:
                components["scripts"] += 1

        print("\nComponent breakdown:")
        for comp, count in components.items():
            if count > 0:
                print(f"  {comp}: {count}")

        print("\nDirectory structure:")
        cmd = f"tree -L 3 {self.output_dir}"
        os.system(cmd)

        print("\nGeneration completed successfully!")
        print("="*60)

    def generate(self):
        """生成整个UVM环境"""
        self.logger.info("Starting UVM environment generation...")

        # 安全检查：验证输出目录
        self._validate_output_dir()

        # 检查输出目录是否存在，如果存在则备份
        if os.path.exists(self.output_dir):
            backup_dir = f"{self.output_dir}_backup_{os.path.basename(self.config['rtl']['top_module'])}"
            self.logger.info(f"Existing output directory found. Creating backup: {backup_dir}")

            try:
                import shutil
                if os.path.exists(backup_dir):
                    shutil.rmtree(backup_dir)
                shutil.copytree(self.output_dir, backup_dir)
                self.logger.info(f"Backup created successfully: {backup_dir}")
            except Exception as e:
                self.logger.warning(f"Failed to create backup: {str(e)}")

        # 创建输出目录
        try:
            os.makedirs(self.output_dir, exist_ok=True)
            self.logger.info(f"Created output directory: {self.output_dir}")
        except Exception as e:
            self.logger.error(f"Failed to create output directory: {str(e)}")
            raise

        # 准备上下文
        context = {
            "config": self.config,
            "agents": self.config.get("agents", []),
            "agent_types": self.agent_def_map,
            "agent_instances": self.agent_instances,
            "items": self.config.get("items", []),
            "interfaces": self.config.get("interfaces", []),
            "item_map": self.item_map,
            "if_map": self.if_map,
        }

        # 保存初始文件列表用于回滚
        initial_files = set(os.listdir(self.output_dir)) if os.path.exists(self.output_dir) else set()

        try:
            # 生成各个组件
            self.logger.info("Generating data components...")
            self.generate_data_components()

            self.logger.info("Generating agents...")
            self.generate_agents(context)

            self.logger.info("Generating common components...")
            self.generate_common_components(context)

            self.logger.info("Generating testbench...")
            self.generate_testbench(context)

            self.logger.info("Generating simulation scripts...")
            self.generate_scripts()

            # 生成完成报告
            self.generate_report()

            self.logger.info("UVM environment generation completed successfully!")

        except Exception as e:
            self.logger.error(f"Generation failed: {str(e)}")
            # 回滚：删除已生成的文件
            self.rollback(initial_files)
            raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UVM Environment Generator")
    parser.add_argument("-c", "--config", default="config.yml", help="Configuration file")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug logging")
    args = parser.parse_args()

    try:
        generator = UVMGenerator(args.config, debug=args.debug)
        generator.generate()
    except Exception as e:
        logging.error(f"Fatal error: {str(e)}")
        sys.exit(1)