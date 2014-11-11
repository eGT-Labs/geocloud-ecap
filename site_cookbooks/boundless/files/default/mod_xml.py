import argparse
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description='Modify Geoserver config files',
                                 prog='mod_xml.py', formatter_class=lambda prog: argparse.HelpFormatter(prog,max_help_position=40))
parser.add_argument('-d', '--data_dir', metavar='', help='Geoserver config dir', required=True)
parsed_args = parser.parse_args()

data_dir = parsed_args.data_dir


xml_tree = ET.parse('{data_dir}/security/usergroup/default/config.xml'.format(data_dir=data_dir))
xml_root = xml_tree.getroot()
if xml_root.find('passwordEncoderName').text != 'digestPasswordEncoder':
    xml_root.find('passwordEncoderName').text = 'digestPasswordEncoder'
xml_tree.write('{data_dir}/security/usergroup/default/config.xml'.format(data_dir=data_dir))