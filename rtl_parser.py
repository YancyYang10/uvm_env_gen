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
        """find top_module, supports parameterized module declaration"""
        # 支持: module name (...) 或 module name #(...) (...)
        # 正则匹配到端口列表开始的 '(' 位置
        pattern = r"module\s+" + re.escape(self.top_module) + r"\s*(?:#\s*\([^)]*\))?\s*\("
        match = re.search(pattern, content)
        if not match:
            print(f"⚠️  Error! Not found {self.top_module} in {self.file_path}")
            return None
        # 返回端口列表 '(' 的位置 (match.end() - 1)
        return match.end() - 1

    def _extract_port_list(self, content, start_pos):
        """从模块开始位置提取端口列表，使用配对括号匹配"""
        # 1. 找到第一个 '(' 的位置（端口列表开始）
        paren_start = content.find('(', start_pos)
        if paren_start == -1:
            return ""

        # 2. 配对匹配找到对应的 ')'
        depth = 1
        pos = paren_start + 1
        while pos < len(content) and depth > 0:
            if content[pos] == '(':
                depth += 1
            elif content[pos] == ')':
                depth -= 1
            pos += 1

        return content[paren_start + 1:pos - 1]

    def parse(self):
        """解析RTL文件获取端口信息"""
        try:
            self.logger.info("Parsing RTL file...")

            with open(self.file_path, 'r') as f:
                content = f.read()

            module_pos = self._find_module(content)
            if module_pos is None:
                raise ValueError(f"Module {self.top_module} not found")

            # 使用配对括号匹配提取端口列表
            ports_str = self._extract_port_list(content, module_pos)
            if not ports_str:
                raise ValueError(f"Failed to parse ports for {self.top_module}")
            # 移除注释
            ports_str = re.sub(r'/\*.*?\*/', '', ports_str, flags=re.DOTALL)
            ports_str = re.sub(r'//.*?$', '', ports_str, flags=re.MULTILINE)
            ports_str = ports_str.strip()

            # 端口模式匹配，支持参数表达式如 [DATA_WIDTH-1:0]
            port_pattern = r'(input|output|inout)\s*(reg|wire|logic)?\s*(signed)?\s*(\[[^\]]+\])?\s*(\w+)'

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
