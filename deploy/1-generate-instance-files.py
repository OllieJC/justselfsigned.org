#!/usr/bin/env python3

import markdown
import re
import os

files = {
    "server.pem": [],
    "key.pem": [],
    "launch-script.sh": [],
    "lightsail-port-info.json": [],
    "../README.md": [],
    "../website/index.html.tmpl": [],
}

for f in files:
    if os.path.exists(f):
        with open(f) as file:
            files[f] = [line.rstrip() for line in file]

server_pem = "\n".join(files["server.pem"])
key_pem = "\n".join(files["key.pem"])

with open("generated-launch-script.sh", "w") as f:
    for line in files["launch-script.sh"]:
        if line == "SERVER_PEM_STRING":
            f.write(server_pem)
            f.write("\n")
        elif line == "KEY_PEM_STRING":
            f.write(key_pem)
            f.write("\n")
        else:
            f.write(line)
            f.write("\n")

readme = []
for mdline in files["../README.md"]:
    if re.match(r"\s*\[COLLAPSE", mdline):
        mdline = re.sub(r"\s*\[(COLLAPSE_.*)\]: \<\> \((.*)\)", r"\1:\2", mdline)
    readme.append(mdline)

with open("../website/index.html", "w") as f:
    for line in files["../website/index.html.tmpl"]:
        if line.strip() == "README.md":
            html = markdown.markdown("\n".join(readme))
            html = re.sub(r"\s*<h1>justselfsigned.org</h1>", "", html)
            html = re.sub(r"<a ", '<a rel="noopener noreferrer" ', html)
            html = re.sub(
                r"<p>COLLAPSE_START:(.*)</p>",
                r'<button type="button" class="collapsible">\1</button><div class="collapsible-content">',
                html,
            )
            html = re.sub(r"<p>COLLAPSE_END:</p>", r"</div>", html)
            f.write(html)
            f.write("\n")
        else:
            f.write(line)
            f.write("\n")
