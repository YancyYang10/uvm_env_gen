#!/bin/python3
import re
import logging

class RTLParser:
    def __init__(self, file_path, top_module):
        self.file_path = file_path
        self.top_module = top_module
        self.ports = []
        self.logger = logging.getLogger(__name__)

        self.logger.info(f"RTL_FILE_PATH:  {self.file_path}")
        self.logger.info(f"RTL_TOP_MODULE: {self.top_module}")

    def _find_module(self, content):
        """find top_module"""
        pattern = r"module\s+(" + re.escape(self.top_module) + r")\s*"
        match = re.search(pattern, content)
        if not match:
            print(f"⚠️  Error! Not found {self.top_module} in {self.file_path}")
            return None
        return match.start()

    def parse(self):
        """解析RTL文件获取端口信息"""
        try:
            self.logger.info("Parsing RTL file...")

            with open(self.file_path, 'r') as f:
                content = f.read()

            module_pos = self._find_module(content)
            if module_pos is None:
                raise ValueError(f"Module {self.top_module} not found")

            module_body = content[module_pos:]
            module_match = re.search(r"module.*?\((.*?)\);", module_body, re.DOTALL)
            if not module_match:
                raise ValueError(f"Failed to parse ports for {self.top_module}")

            ports_str = module_match.group(1)
            # 移除注释
            ports_str = re.sub(r'/\*.*?\*/', '', ports_str, flags=re.DOTALL)
            ports_str = re.sub(r'//.*?$', '', ports_str, flags=re.MULTILINE)
            ports_str = ports_str.strip()

            # 端口模式匹配，支持更复杂的端口声明
            port_pattern = r'(input|output|inout)\s*(reg|wire|logic)?\s*(signed)?\s*(\[.*?\])?\s*(\w+)'

            self.ports = []
            port_matches = list(re.finditer(port_pattern, ports_str))

            if not port_matches:
                self.logger.warning("No ports found in RTL file")
                return []

            for port in port_matches:
                port_info = {
                    "name": port.group(5),
                    "direction": port.group(1),
                    "width": port.group(4) or ""
                }
                self.ports.append(port_info)

                # 记录前几个端口用于调试
                if len(self.ports) <= 5:
                    self.logger.debug(f"Port: {port_info}")

            self.logger.info(f"Parsed {len(self.ports)} ports from RTL")
            return self.ports

        except FileNotFoundError:
            self.logger.error(f"RTL file not found: {self.file_path}")
            raise
        except Exception as e:
            self.logger.error(f"RTL parse error: {str(e)}")
            raise
