import frontmatter
from pathlib import Path
from typing import List

from .Middleware import Middleware

class FrontMatterProcessor(Middleware):
    def __init__(self, files: List[Path]):
        self.aggregate_frontmatter = {}
        for file in files:
            document = frontmatter.load(file)
            metadata = document.metadata
            directories = list(file.parts) | {"__IS_FILE__": True}
            while directories:
                metadata = {directories.pop(): metadata}
            self.aggregate_frontmatter = combine_dicts(self.aggregate_frontmatter, metadata)

    def process(self, context: dict, file: Path):
        document = frontmatter.load(file)
        context |= document.metadata
        file.write_text(document.content)

def combine_dicts(dict1: dict, dict2: dict):
    combined_dict = {}
    
    for key, value in dict1.items():
        if key in dict2:
            if isinstance(value, dict) and isinstance(dict2[key], dict):
                combined_dict[key] = combine_dicts(value, dict2[key])
            else:
                combined_dict[key] = [value, dict2[key]]
        else:
            combined_dict[key] = value
    
    for key, value in dict2.items():
        if key not in combined_dict:
            combined_dict[key] = value
    
    return combined_dict
