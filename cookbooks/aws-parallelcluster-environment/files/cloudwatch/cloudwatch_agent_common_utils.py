import json
import os
import sys

from jinja2 import FileSystemLoader
from jinja2.sandbox import SandboxedEnvironment

CONFIG_ARGS = {
    "default_platforms": ["amazon", "centos", "redhat", "rocky", "ubuntu"],
}


def render_jinja_template(template_file_path):
    file_loader = FileSystemLoader(str(os.path.dirname(template_file_path)))
    env = SandboxedEnvironment(loader=file_loader)
    rendered_template = env.get_template(os.path.basename(template_file_path)).render(**CONFIG_ARGS)
    with open(template_file_path, "w", encoding="utf-8") as f:
        f.write(rendered_template)
    return template_file_path


def read_jinja_template_at(path):
    """Read the JSON file at path as a Jinja template."""
    try:
        with open(render_jinja_template(path), encoding="utf-8") as input_file:
            return json.load(input_file)
    except FileNotFoundError:
        fail(f"No file exists at {path}")
    except ValueError:
        fail(f"File at {path} contains invalid JSON")
    return None


def fail(message):
    """Exit nonzero with the given error message."""
    sys.exit(message)
