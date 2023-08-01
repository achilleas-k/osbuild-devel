import json
import os
import sys


def read_all(filepath):
    with open(filepath) as all_file:
        return json.load(all_file)


def filter_newest(repos):
    """
    For each distro, arch, and repo name, return just the newest one.
    """
    repo_map: dict[str, list] = {}

    # collect all repos that have the same name (without date)
    for repo in repos:
        if "beta" in repo:
            # skip beta repos
            continue
        repo_date = repo.split("-")[-1]
        if len(repo_date) > 8:
            # some older snapshots include more than date: ignore them
            continue
        reponame = repo[:-8]
        repo_group = repo_map.get(reponame, [])
        repo_group.append(repo)
        repo_map[reponame] = repo_group

    newest = []
    for repo_group in repo_map.values():
        newest.append(sorted(repo_group)[-1])

    return newest


def create_repo_map(repo_list):
    repo_map = {}
    for repo_name in repo_list:
        components = repo_name.split("-")
        if len(components) < 2:
            continue

        name = "-".join(repo_name.split("-")[:-1])
        repo_map[name] = repo_name

    return repo_map


def update_files(repo_map, directory):
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        if not filepath.endswith(".json"):
            print(f"Non-json file found in destination: {filepath}")
            continue

        with open(filepath) as repofile:
            filedata = json.load(repofile)
        new_filedata = {}
        for arch, arch_repos in filedata.items():
            new_arch_repos = []
            for file_repo_data in arch_repos:
                old_url = file_repo_data["baseurl"]
                old_name = old_url.strip("/").split("/")[-1]
                repo_base = "-".join(old_name.split("-")[:-1])
                new_name = repo_map[repo_base]
                file_repo_data["baseurl"] = old_url.replace(old_name, new_name)
                new_arch_repos.append(file_repo_data)
            new_filedata[arch] = new_arch_repos
        with open(filepath, "w", encoding="utf-8") as repofile:
            json.dump(new_filedata, repofile, indent=2)


def main():
    all_repos_file = sys.argv[1]  # output of curl -s https://rpmrepo.osbuild.org/v2/enumerate/
    dest_dir = sys.argv[2]  # should already contain repo files

    all_repo_names = read_all(all_repos_file)
    newest = filter_newest(all_repo_names)
    repo_map = create_repo_map(newest)

    update_files(repo_map, dest_dir)
    print("URLs updated")
    print("Use the following command to inspect:")
    print("git diff --word-diff-regex='[a-z0-9]+' test/data/")


if __name__ == "__main__":
    main()
