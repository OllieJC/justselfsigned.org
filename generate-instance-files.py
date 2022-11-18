#!/usr/bin/env python3

files = {
    "server.pem": [],
    "key.pem": [],
    "launch-script.sh": [],
    "lightsail-port-info.json": [],
}

for f in files:
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
