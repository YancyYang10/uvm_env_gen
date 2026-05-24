#!/usr/bin/python3
from mako.template import Template
import os
import yaml
import argparse
import logging
import sys
from rtl_parser import RTLParser

class UVMGenerator:
    def __init__(self, config_path, debug=False):
        # 设置日志系统
        self.setup_logging(debug)
        self.logger = logging.getLogger(__name__)
        self.verilog_files = []

        # 设置模板目录
        self.template_dir = str(os.getenv('UVM_GEN_DIR', ""))+"/templates"

        # 加载配置
        self.config = self.load_config(config_path)

        # 初始化变量
        self.output_dir = self.config.get("output_dir", "uvm_env")
        self.item_map = {}
        self.if_map = {}

        # 映射配置
        if "items" in self.config:
            self.item_map = {item["name"]: item for item in self.config["items"]}
        if "interfaces" in self.config:
            self.if_map = {interface["name"]: interface for interface in self.config["interfaces"]}

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

    def load_config(self, config_path):
        """加载并验证配置文件"""
        self.logger.info(f"Loading configuration from: {config_path}")

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
        """生成所有Agent组件"""
        self.logger.info("Generating agents...")
        agent_templates = [
            ('driver.mako', 'uvm_tb/${name}_agent/${name}_driver.sv'),
            ('monitor.mako', 'uvm_tb/${name}_agent/${name}_monitor.sv'),
            ('sequencer.mako', 'uvm_tb/${name}_agent/${name}_sequencer.sv'),
            ('agent.mako', 'uvm_tb/${name}_agent/${name}_agent.sv'),
            ('sequence.mako', 'uvm_tc/seq/${name}_sequence.sv')
        ]

        for agent in self.config["agents"]:
            try:
                agent_name = agent["name"]
                self.logger.debug(f"Generating agent: {agent_name}")

                item_name = agent["item"]
                if_name = agent["interface"]

                ctx = {
                    "agent": agent,
                    "item": self.item_map[item_name],
                    "item_name": item_name,
                    "intf": self.if_map[if_name],
                    "if_name": if_name,
                    **context
                }

                for tpl, pattern in agent_templates:
                    try:
                        output_file = Template(pattern).render(**agent)
                        self.render_template(tpl, ctx, output_file)
                    except Exception as e:
                        self.logger.error(f"Failed to generate {agent_name} {tpl}: {str(e)}")
                        raise

                self.logger.info(f"Successfully generated agent: {agent_name}")

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

                if tpl == 'top_cfg.mako':
                    self.verilog_files.insert(0, output_file)
                else:
                    self.verilog_files.append(output_file)

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
            with open(tb_path, "w") as flist_file:
                for sv_file in self.verilog_files:
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
            "agents": self.config["agents"],
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