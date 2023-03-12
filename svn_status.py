import json
import subprocess
import csv
import re

base_url = 'http://monaco:9000'


def get_repos():
    with open('svn_repos.json') as json_file:
        return json.load(json_file)

def get_authors(branch_url):
    url = base_url + branch_url
    output = subprocess.run(["svn", "log", url], capture_output=True).stdout.decode('iso8859-1')
    pattern = re.compile(r'r\d\s\|\s([a-z]+)\s\|')
    return ','.join(set(re.findall(pattern, output)))

def get_repo_status(repo_sub_title):
    return 'ACTIVE' if repo_sub_title.find('--RETIRED--') == -1 else 'RETIRED'

def get_branch_count(branch_url):
    url = base_url + branch_url + '/branches'
    output = subprocess.run(["svn", "ls", url], capture_output=True).stdout.decode('iso8859-1')
    return len(list(filter(None, output.split('\r\n'))))

def get_repo_type(branch_url):
    return 'NO_BRANCHES' if get_branch_count(branch_url) == 0 else 'HAS_BRANCHES'

def save_csv(rows):
    with open('status.csv', 'w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(['Repository Name', 'Status', 'Repository Type', 'Branch Count', 'Branch Authors'])
        writer.writerows(rows)

def build_row(repo):
    authors = get_authors(repo['url'])
    branch_count = get_branch_count(repo['url'])
    repo_type = get_repo_type(repo['url'])
    repo_status = get_repo_status(repo['subTitle'])
    repo_name = repo['title']
    return [repo_name, repo_status, repo_type, branch_count, authors]

def main():
    repos = get_repos()
    data = []
    for repo in repos:
        row = build_row(repo)
        print(row)
        data.append(row)
    save_csv(data)


if __name__ == "__main__":
    main()
