from xml.dom.minidom import parse, parseString
import urllib.request
import json

url='https://gitlab.jmmb.com'
private_token='PLACE TOKEN HERE'
request_headers = {'PRIVATE-TOKEN': private_token}

def find_project(project_name):
    request_url = 'https://gitlab.jmmb.com/api/v4/projects'
    query = {'search': project_name}
    query_string = urllib.parse.urlencode(query) 
    request_url = request_url + "?" + query_string 
    req = urllib.request.Request(request_url, data=None, headers=request_headers, method='GET')
    with urllib.request.urlopen(req) as response: 
        response_text = response.read().decode('latin-1')
        return json.loads(response_text)
    
def update_project_desc(id, description):
    request_url = 'https://gitlab.jmmb.com/api/v4/projects/{}'.format(id)
    data = 'description={}'.format(description).encode('utf-8')
    req = urllib.request.Request(request_url, data=data, headers=request_headers, method='PUT')
    with urllib.request.urlopen(req) as response:
        return 'status = {}, reason = {}'.format(response.status, response.reason)

def main():
    with open("repos.xml") as file:
        document = parse(file)
        repos = document.getElementsByTagName("repo")
        count = 0
        for repo in repos:
            name = repo.getAttribute("name")
            description = repo.getAttribute("desc")
            projects = find_project(name)
            if projects:
                if len(projects) > 0:
                    count = count + 1
                    project = projects[0]
                    try:
                        response = update_project_desc(project['id'], description)
                    except urllib.error.HTTPError as e:
                        response = 'status = {}, reason = {}'.format(e.status, e.reason)
                    print('count: {}, id: {}, name: {}, response = {}'.format(count, project['id'], project['name'], response))

if __name__ == "__main__":
    main()