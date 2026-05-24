#!/usr/bin/python3
from mako.template import Template
import os
import yaml
import argparse
from rtl_parser import RTLParser

class UVMGenerator:
    def __init__(self, config_path):
        self.config = self.load_config(config_path)
        self.template_dir = str(os.getenv('UVM_GEN_DIR'))+"/templates"
        self.output_dir = self.config.get("output_dir", "uvm_env")
        self.item_map = {item["name"]: item for item in self.config["items"]}
        self.if_map = {interface["name"]: interface for interface in self.config["interfaces"]}
        self.verilog_files = []
        print(f"INFO! OUT_PUT_PATH:   {self.output_dir}")
        print(self.if_map['apb_if']['clock']);

    def load_config(self, config_path):
        with open(config_path) as f:
            return yaml.safe_load(f)

    def render_template(self, template_name, context, output_file):
        tpl_path = os.path.join(self.template_dir, template_name)
        with open(tpl_path) as f:
            tpl = Template(f.read())
            code = tpl.render(**context)
            
            output_path = os.path.join(self.output_dir, output_file)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "w") as out:
                out.write(code)

    def generate_agents(self, context):
        agent_templates = [
            ('driver.mako', 'uvm_tb/${name}_agent/${name}_driver.sv'),
            ('monitor.mako', 'uvm_tb/${name}_agent/${name}_monitor.sv'),
            ('sequencer.mako', 'uvm_tb/${name}_agent/${name}_sequencer.sv'),
            ('agent.mako', 'uvm_tb/${name}_agent/${name}_agent.sv'),
            ('sequence.mako', 'uvm_tc/seq/${name}_sequence.sv')
        ]

        for agent in self.config["agents"]:
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
                output_file = Template(pattern).render(**agent)
                self.render_template(tpl, ctx, output_file)
                self.verilog_files.append(output_file)

    def generate_common_components(self, context):
        # Generate CFG, ENV, VSQR, RM, SCB, COV, TC
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
            output_file = Template(output_pattern).render(config=self.config)
            self.render_template(tpl, context, output_file)
            if tpl == 'top_cfg.mako':
                self.verilog_files.insert(0,output_file)
            else:
                self.verilog_files.append(output_file)

    def generate_testbench(self, context):
        rtl_ports = []
        if 'top_file' in self.config['rtl'] and 'top_module' in self.config['rtl']:
            parser = RTLParser(
                self.config['rtl']['top_file'],
                self.config['rtl']['top_module']
            )

            try:
                rtl_ports = parser.parse()
            except Exception as e:
                print(f"⚠️  RTL PARSE WARNING: {str(e)}")
                print("DUT Ports May Be Wrong!")
   
        context['rtl_ports'] = [{
            "name": port['name'],
            "direction": port['direction'],
            "width": port.get('width', '')
        } for port in rtl_ports]
        
        output_file=f"bench/{self.config['testbench']['name']}.sv"
        self.render_template('testbench.mako', context, output_file)
        self.verilog_files.append(output_file)

    def generate_data_components(self):
        # Generate Interfaces
        for interface in self.config["interfaces"]:
            output_pattern = f'uvm_tb/interfaces/{interface["name"]}.sv'
            output_file = Template(output_pattern).render(config=self.config)
            self.render_template('interface.mako',
                                {"interface": interface},
                                output_file)
            self.verilog_files.append(output_file)

        # Generate Items
        for item in self.config["items"]:
            output_pattern = f'uvm_tb/items/{item["name"]}.sv'
            output_file = Template(output_pattern).render(config=self.config)
            self.render_template('item.mako', 
                               {"item": item},
                               output_file)
            self.verilog_files.append(output_file)


    def generate_scripts(self):
        # Generate Makefile, run.tcl
        rsim_dir = os.path.join(self.output_dir, "rsim")
        os.makedirs(rsim_dir, exist_ok=True)
        makefile_template = os.path.join(self.template_dir, "Makefile")
        makefile_output = os.path.join(rsim_dir, "Makefile")
        cmd = f"cp {self.template_dir}/Makefile  {rsim_dir};"
        cmd += f"cp {self.template_dir}/run.tcl {rsim_dir};"
        cmd += f"cp {self.template_dir}/cm.cfg {rsim_dir};"
        cmd += f"cp {self.config['rtl']['flist']} {rsim_dir}"
        os.system(cmd)

        tb_path = os.path.join(rsim_dir, "tb.f")
        with open(tb_path, "w") as flist_file:
            for sv_file in self.verilog_files:
                flist_file.write(f"../{sv_file}\n")

    def generate(self):
        os.makedirs(self.output_dir, exist_ok=True)
        context = {
            "config": self.config,
            "agents": self.config["agents"],
            "items": self.config["items"],
            "interfaces": self.config["interfaces"],
            "item_map": self.item_map,
            "if_map": self.if_map,
        }

        self.generate_data_components()
        self.generate_agents(context)
        self.generate_common_components(context)
        self.generate_testbench(context)
        self.generate_scripts()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UVM Environment Generator")
    parser.add_argument("-c", "--config", default="config.yml", help="Configuration file")
    args = parser.parse_args()
    
    generator = UVMGenerator(args.config)
    generator.generate()
    print(f"\n********************************** REPORT *********************************")
    print(f"Uvm_gen script was executed completely!")
    print(f"Env was generated in {generator.output_dir}/")
    print(f"Env structure is as follows:\n")
    cmd = f"tree {generator.output_dir}"
    os.system(cmd)
    print(f"****************************************************************************\n")
