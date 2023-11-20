import os

from jinja2 import FileSystemLoader
from jinja2.sandbox import SandboxedEnvironment

CONFIG_ARGS = {
    "default_platforms": ["amazon", "centos", "redhat", "rocky", "ubuntu"],
}


def render_jinja_template(template_file_path):
    """Override the file at template_file_path with the rendered json file."""
    file_loader = FileSystemLoader(str(os.path.dirname(template_file_path)))
    env = SandboxedEnvironment(loader=file_loader)
    rendered_template = env.get_template(os.path.basename(template_file_path)).render(**CONFIG_ARGS)
    with open(template_file_path, "w", encoding="utf-8") as f:
        f.write(rendered_template)
    return template_file_path
