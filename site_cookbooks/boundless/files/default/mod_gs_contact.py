import requests
import argparse
import json

parser = argparse.ArgumentParser(description='Modify Geoserver default contact',
                                 prog="mod_gs_contact.py", formatter_class=lambda prog: argparse.HelpFormatter(prog,max_help_position=40))
parser.add_argument('-u', '--user', metavar='', required=True, help='Geoserver User Name')
parser.add_argument('-p', '--password', metavar='', required=True, help='Geoserver Password')
parser.add_argument('-url', '--rest_url', metavar='', help='Geoservers REST API endpoint', default='http://localhost:8080/geoserver/rest')
parsed_args = parser.parse_args()

user = parsed_args.user
password = parsed_args.password
url = '{url}/settings/contact.json'.format(url=parsed_args.rest_url)

contact_info_req = requests.get(url, auth=(user, password))
if contact_info_req.status_code == 200:
    contact_info = contact_info_req.json()
    print "Got Geoserver Contact Info"
    contact_info['contact']['contactEmail'] = 'support@eglobaltech.com'
    contact_info['contact']['contactOrganization'] = 'eGT'
    contact_info['contact']['contactPerson'] = 'eGT Support'
    contact_info['contact']['addressCountry'] = 'USA'
    contact_info['contact']['contactPosition'] = 'Customer Support'
    contact_info['contact']['addressCity'] = 'Arlington'
    contact_info['contact']['address'] = 22203
    contact_info['contact']['addressState'] = 'VA'
    contact_info['contact']['addressPostalCode'] = '3865 Wilson Blvd, Suite 500'
    contact_info['contact']['onlineResource'] = 'www.eglobaltech.com'
    contact_info = json.dumps(contact_info)

    headers = {'content-type': 'application/json'}
    update_contact_info = requests.put(url=url, headers=headers, data=contact_info, auth=(user, password))
    if update_contact_info.status_code == 200:
        print "Updated Geoserver Contact Info"
    else:
        print "failed to update Geoserver Contact Info, See error: {http_error}".format(http_error=update_contact_info.text())
    
else:
    print "failed to get Geoserver Contact Info, See error: {http_error}".format(http_error=contact_info.text())
