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


def _repourl(repo, version):
    if repo[:4] == "http":
        return repo

    composes = {
        "9.6": "https://download.devel.redhat.com/rhel-9/composes/RHEL-9/RHEL-9.6.0-updates-20251020.1",
    }

    compose = composes[version]

    return f"{compose}/compose/{repo}/$arch/os/"


def start_build(config, release):
    name = config["name"]
    version = config["version"]
    distro = config["distro"]
    arches = config["arches"]
    image_types = config["image_types"]
    repos = config["repo"]
    target = config["target"]

    cmd = ["brew", "osbuild-image"]
    for repo in repos:
        cmd += ["--repo", _repourl(repo, version)]

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
    release = sys.argv[2]
    with open(config_path, encoding="utf-8") as config_file:
        configs = json.load(config_file)

    for config in configs:
        start_build(config, release)


if __name__ == "__main__":
    main()
