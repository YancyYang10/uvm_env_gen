#!/bin/python3
import re

class RTLParser:
    def __init__(self, file_path, top_module):
        self.file_path = file_path
        self.top_module = top_module
        self.ports = []
        print(f"INFO! RTL_FILE_PATH:  {self.file_path}")
        print(f"INFO! RTL_TOP_MODULE: {self.top_module}")

    def _find_module(self, content):
        """find top_module"""
        pattern = r"module\s+(" + re.escape(self.top_module) + r")\s*"
        match = re.search(pattern, content)
        if not match:
            print(f"⚠️  Error! Not found {self.top_module} in {self.file_path}")
            return None
        return match.start()

    def parse(self):
        try:
            with open(self.file_path, 'r') as f:
                content = f.read()

            module_pos = self._find_module(content)
            if module_pos is None:
                return []

            module_body = content[module_pos:]
            module_match = re.search(r"module.*?\((.*?)\);", module_body, re.DOTALL)
            if not module_match:
                print(f"⚠️  Error! Prase {self.top_module} ports fail!")
                return []
            
            ports_str = module_match.group(1)
            ports_str = re.sub(r'/\*.*?\*/', '', ports_str, flags=re.DOTALL)
            ports_str = re.sub(r'//.*?$', '', ports_str, flags=re.MULTILINE)
            ports_str.strip()
            port_pattern = r'(input|output|inout)\s*(reg|wire)?\s*(signed)?\s*(\[.*?\])?\s*(\w+)'
            
            self.ports = []
            for port in re.finditer(port_pattern, ports_str):
                self.ports.append({
                    "name": port.group(5),
                    "direction": port.group(1),
                    "width": port.group(4) or ""
                })
            if len(self.ports) == 0:
                print(f"⚠️  Warning! RTL Prase Fail! No Port Got! Return Null!")
                return []

            return self.ports

        except Exception as e:
            print(f"⚠️  Error! RTL Prase Fail!")
            return []
