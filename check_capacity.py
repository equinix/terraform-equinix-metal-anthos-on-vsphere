import subprocess
import requests
import json


default_file = "variables.tf"
variable_file = "terraform.tfvars"
router_host_count = 1
url = "https://api.packet.net/capacity"


##Capture default variables
def set_default_variables(variable, file):
  cmd = 'cat ' + file + " | awk '/" + variable + "/ { getline; print $3}'"
  v = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().strip('"')
  return v

##Check to see if the user has set different variables
def check_set_variables(variable, file1, file2):
  with open(file1) as f:
    if variable in f.read():
      cmd = 'cat ' + file1 + " | awk '/" + variable + "/ { print $3}'"
      v = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().strip('"')
      print ("Using the user variable for " + variable + ": ", end='')
    else:
      v = set_default_variables(variable, file2)
      print ("Using the default value for " + variable + ": ", end='')
    print (v)
    return v

#capture packet token
packet_token = subprocess.check_output("cat terraform.tfvars | awk '/auth_token/ { print $3}'", shell=True, universal_newlines=True).strip().strip('"')

def main():

  facility = check_set_variables("facility", variable_file, default_file)
  router_size = check_set_variables("router_size", variable_file, default_file)
  esxi_size = check_set_variables("esxi_size", variable_file, default_file)
  esxi_host_count = int(check_set_variables("esxi_host_count", variable_file, default_file))

## Print new lines for formating
  print ('\n' * 2)


## Build the json
  if router_size == esxi_size:
    same_size = True
    servers=[(facility, router_size, router_host_count + esxi_host_count)]
  else:
    same_size = False
    servers=[(facility, router_size, router_host_count), (facility, esxi_size, esxi_host_count)]
  servers_json = {"servers":[]} 
  for server in servers: 
    servers_json["servers"].append( {"facility": server[0], "plan": server[1], "quantity": server[2]} )

## Using requests to validate capacity
  header= {"X-Auth-Token": packet_token}
  r = requests.post(url, headers=header, json=servers_json)

# Uncomment the print response below for troubleshooting purposes
  #print (r.json())

##Print the results
# TDOO: color code the outputs
  if same_size :
    print ("Are there " + str(router_host_count + esxi_host_count) + " " + router_size + " instances available for all servers in " + facility + "?")
    if (r.json()['servers'][0]['available']):
      print ("Yes")
    else:
      print ("No, select another facility or router and ESXi size.")
  else:
    print ("Is there 1 " + router_size + " instance available for the router in " + facility + "?")
    if (r.json()['servers'][0]['available']):
      print ("Yes")
    else:
      print ("No, select another facility or router size.")

    if esxi_host_count > 1:
      is_are = "Are"
      plural = "s"
    else:
      is_are = "Is"
      plural = ""

    print ("\n" + is_are + " there " + str(esxi_host_count) + " " + esxi_size + " instance" + plural +" available for ESXi in " + facility + "?")
    if (r.json()['servers'][1]['available']):
      print ("Yes")
    else:
      print ("No, select another facility, ESXi size, or number of ESXi hosts.")

main()
