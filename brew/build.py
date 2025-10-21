import json
import subprocess as sp
import sys
from contextlib import contextmanager
from tempfile import NamedTemporaryFile


@contextmanager
def _mk_customizations_file(customizations):
    with NamedTemporaryFile() as tmpfile:
        c = json.dumps(customizations)
        tmpfile.write(c.encode("utf-8"))
        tmpfile.flush()
        yield tmpfile.name


def start_build(config):
    name = config["name"]
    version = config["version"]
    distro = config["distro"]
    arches = config["arches"]
    image_types = config["image_types"]
    repos = config["repo"]
    target = config["target"]
    release = config["release"]

    cmd = ["brew", "osbuild-image"]
    for repo in repos:
        cmd += ["--repo", repo]

    cmd += ["--release", release]

    cmd += [name, version, distro, target, *arches]

    cmd += ["--nowait"]
    with _mk_customizations_file(config["customizations"]) as customizations:
        cmd += ["--customizations", customizations]

        for image_type in image_types:
            cmd_it = cmd + ["--image-type", image_type]
            print(" ".join(cmd_it))
            sp.run(cmd_it, check=True)


def main():
    config_path = sys.argv[1]
    with open(config_path, encoding="utf-8") as config_file:
        configs = json.load(config_file)

    for config in configs:
        start_build(config)


if __name__ == "__main__":
    main()
