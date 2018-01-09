"""datapower"""
import urllib2
import ssl
import json
from settings import MGM_URI, USER, PASSWORD, TOP_LEVEL_URL

def main():
    """main"""
    # get_domains()
    # get_aliases()
    get_config()

def get_domains():
    """read_config_from_file"""

    with open('json/mgmt_domains_config.json') as json_data:
        domains = json.load(json_data)['domain']
        for domain in domains:
            print domain["name"]

def get_aliases():
    """get_aliases"""

    with open('json/mgmt_config_default_HostAlias.json') as json_data:
        domains = json.load(json_data)['HostAlias']
        for domain in domains:
            print domain["name"] + ': ' + domain['IPAddress']

def get_config():
    """get_config - not working from desktop (basic auth / proxy"""
    print MGM_URI
    print USER
    print PASSWORD

    # datapower certificate cannot be validated
    ssl._create_default_https_context = ssl._create_unverified_context # pylint: disable=W0212
    password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, TOP_LEVEL_URL, USER, PASSWORD)
    password_handler = urllib2.HTTPBasicAuthHandler(password_mgr)
    proxy_handler = urllib2.ProxyHandler({})

    opener = urllib2.build_opener(password_handler, proxy_handler)
    response = opener.open(MGM_URI)
    print response

if __name__ == '__main__':
    main()
