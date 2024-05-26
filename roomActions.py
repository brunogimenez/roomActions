import sys
import requests
import time
import json
import subprocess
import re
from datetime import datetime


roomId = "Y2lzY29zcGFyazovL3VzL1JPT00vNjU1NDJkMzAtMjU3OS0xMWVlLWFlZmMtMmYzN2RkZmVlMTg2"
params = {'roomId' : roomId, 'max' : 1000}

# create a file with the tokens and change the path below
# each token should occupy one line, without any quotes, otherwise it needs to be treated
with open ('/Users/bgimenez/partnerStats/roomActions/tokens', 'r') as file:
    lines = [line.strip() for line in file.readlines()]
    token_bot = lines[0]
    token_personal = lines[1]
    file.close()
    
url = "https://webexapis.com/v1/"
sub_url_messages = "messages"
sub_url_membership= "memberships"
headers = {'Authorization': 'Bearer ' + token_bot}

def getMessages():
    headers = {'Authorization': 'Bearer ' + token_personal}
    message_url = f"{url}{sub_url_messages}"
    #MODIFY THIS < > before, so add the latest date
    before = "2024-02-06T00:00:00.000Z"
    maxDate = 1000 
    params = {'roomId' : roomId, 'before' : before, 'max' : maxDate}
    return requests.get (message_url, headers=headers, params=params)

def getMembership(targetURL = None):
   if targetURL is None:
       message_url = f"{url}{sub_url_membership}"
       params = {'roomId' : roomId, 'max' : 1000} 
       response = requests.get (message_url, headers=headers, params=params)
       total_membership_data = [response.json()]
       #total_membership_data = response.json()

       # Check if there are more pages (pagination)
       while 'link' in response.headers:
           has_next_page = False
           for link in response.headers['link'].split(','):
               link_url, link_rel = link.split(';')
               if 'next' in link_rel:
                   next_page_url = re.search(r'<(https://.*?)>', link_url).group(1)
                   response = requests.get(next_page_url, headers=headers)
                   total_membership_data.append(response.json())
                   has_next_page = True
                   break

           if not has_next_page:
               break

       return total_membership_data

def addMembership(email):
    membership_url = f"{url}{sub_url_membership}"
    params = {'roomId' : roomId, 'personEmail' : email, 'isModerator': 'false'}
    return requests.post(membership_url, headers=headers, json=params)

def deleteMembership(idMemberToBeDeleted):
    membership_url = f"{url}{sub_url_membership}/"
    with open (f'{idMemberToBeDeleted}', 'r') as f:
        idMember = f.readlines()
    for i in idMember:
        print (f"Deleting... {i}")
        requests.delete(membership_url + i, headers=headers)

def addPoints(email, points=None):
    headers = {'Authorization': 'Bearer ' + token_personal}
    message_url = f"{url}{sub_url_messages}"
    addpointMsg = "sec3po addpoint "
    toPersonEmail = 'comunidadebr@webex.bot'  #Sec3PO bot
    if not points:
        points = 1
        message_data = {"toPersonEmail": toPersonEmail, "markdown": f"{addpointMsg} {email} {points}"}
        response = requests.post(message_url, headers=headers, json=message_data)
    else:
        message_data = {"toPersonEmail": toPersonEmail, "markdown": f"{addpointMsg} {email} {points}"}
        response = requests.post(message_url, headers=headers, json=message_data)

    return response 

if sys.argv[1] == "GetMessages":
    print (f"Getting messages using personal token...")
    timestamp = datetime.now().strftime("%Y-%m-%d")
    with open (f'file6MonthsMessageRaw_{timestamp}.json', 'w') as f:
        json.dump(getMessages().json(), f, indent=4)
        f.close()
elif sys.argv[1] == "GetMembership":
    print (f"Getting membership...")
    timestamp = datetime.now().strftime("%Y-%m-%d")
    with open (f'PeopleMembershipRoomRaw_{timestamp}.json', 'w') as f:
        json.dump(getMembership(), f, indent=4)
        f.close()
elif sys.argv[1].startswith ("DelMembership"):
    print (f"Deleting membership ...")
    deleteMembership(sys.argv[2])
elif sys.argv[1].startswith ("AddMembership"):
    print (f"Adding membership ...")
    addMembership(sys.argv[2])
elif sys.argv[1].startswith ("AddPoints"):
    print (f"Adding points ...")
    addPoints(sys.argv[2], sys.argv[3])
else:
    print (f"Not available {sys.argv[1]}")


