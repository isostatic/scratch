#!/usr/bin/python3
import sys
import requests
import json
import subprocess
import re

def ping_ip(ip_address):
    output = ""
    try:
        output = subprocess.check_output(['ping', '-c', '1', '-w', '3', ip_address]).decode('utf-8')
        rtt = re.search(r'time=(\d+(\.\d+)?|\.\d+)\s?ms', output)
        return float(rtt.group(1))
    except subprocess.CalledProcessError:
        print(output)
        pass
    return None

def plotEP(continent, city, gre, hostname):
    tla = hostname.split(".")[0].upper()
    continent = continent.split(":")[1].strip()
    city = city.split(":")[1].strip()
    rtt = ping_ip(hostname)
    print(f"{city}, {tla}, {gre}, {rtt}")

zsc = "zscaler.net"
if (len(sys.argv)) > 1:
    zsc = sys.argv[1]

url = f"https://api.config.zscaler.com/{zsc}/cenr/json"
response = requests.get(url)
if response.status_code == 200:
    data = response.json()
    data = data[zsc]
    for continent, cities in data.items():
        for city, entries in cities.items():
            if isinstance(entries, list):
                for entry in entries:
                    gre = entry.get('gre')
                    hostname = entry.get('hostname')
                    if gre and hostname:
                        gre = entry['gre']
                        hostname = entry['hostname']
                        plotEP(continent, city, gre, hostname)
