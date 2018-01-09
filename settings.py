"""settings"""
MGMT_IP = '10.69.0.10'
MGMT_PORT = '5554'
MGMT_URI = 'https://' + MGMT_IP + ':' + MGMT_PORT + '/mgmt/'
DOMAINS_URI = MGMT_URI + 'domains/config/'
ALIASES_URI = MGMT_URI + 'config/default/HostAlias'

USER = 'readonly'
PASSWORD = '1234pcis'
