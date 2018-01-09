"""datapower"""
import json
import requests
from settings import USER, PASSWORD, MGMT_URI, DOMAINS_URI, ALIASES_URI

def main():
    """main"""
    print get_config(MGMT_URI)
    aliases = get_config(ALIASES_URI)['HostAlias']
    for alias in aliases:
        print alias['name'] + ': ' + alias['IPAddress']
    domains = get_config(DOMAINS_URI)['domain']
    for domain in domains:
        print domain['name']


def get_config(url):
    """get_config"""
    return json.loads(requests.get(url, auth=(USER, PASSWORD), verify=False).content)

if __name__ == '__main__':
    main()
