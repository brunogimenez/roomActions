#! /bin/bash


InitEnv() {
source actions/bin/activate

idAndEmailMembers=idAndEmailMembers_`date | awk '{print $2 $NF}'` 
EmailMembersnoCisco=EmailMembernoCisco_`date | awk '{print $2 $NF}'`
EmailMemberswithCisco=EmailMemberswithCisco_`date | awk '{print $2 $NF}'`
fileCreatedPersonEmailFieldRaw=fileCreatedPersonEmailFieldRaw_`date | awk '{print $2 $NF}'`
personEmailCreated=personEmailCreatedFields_`date | awk '{print $2 $NF}'`
EmailwithActivity=EmailwithActivity_`date | awk '{print $2 $NF}'`
finalActivity=finalActivityLast6Months_`date | awk '{print $2 $NF}'`
DomainsNumberMessages=Domains+NumberMessages_`date | awk '{print $2 $NF}'`
DomainsNumberPeoplewithMessages=Domains+NumberPeoplewithMessages_`date | awk '{print $2 $NF}'`
onlyDomainsLast6Months=onlyDomainsLast6Months_`date | awk '{print $2 $NF}'`
onlyDomainsNumberPeopleOverall=onlyDomains+NumberPeopleOverall_`date | awk '{print $2 $NF}'`
EmailnoActivity=EmailnoActivity_`date | awk '{print $2 $NF}'`
idMemberToBeDeleted=idMemberToBeDeleted_`date | awk '{print $2 $NF}'`

}

Membership() {
#Membership manipulation python
python roomActions.py GetMembership

#Manipulation bash
PeopleMembership=`ls PeopleMembershipRoomRaw*` 

grep -e '\"id\"' $PeopleMembership > idMembers
grep -e 'personEmail' $PeopleMembership > emailMember

#gsub all non-standards characters
awk '{
  gsub(/\\u00e1/, "á");
  gsub(/\\u00e9/, "é");
  gsub(/\\u00ed/, "í");
  gsub(/\\u00f3/, "ó");
  gsub(/\\u00fa/, "ú");
  gsub(/\\u00c1/, "Á");
  gsub(/\\u00c9/, "É");
  gsub(/\\u00cd/, "Í");
  gsub(/\\u00d3/, "Ó");
  gsub(/\\u00da/, "Ú");
  gsub(/\\u00e3/, "ã");
  gsub(/\\u00c3/, "Ã");
  gsub(/\\u00f5/, "õ");
  gsub(/\\u00d5/, "Õ");
  gsub(/\\u00ea/, "ê");
  gsub(/\\u00ca/, "Ê");
  gsub(/\\u00f4/, "ô");
  gsub(/\\u00d4/, "Ô");
  gsub(/\\u00e7/, "ç");
  gsub(/\\u00c7/, "Ç");
  gsub(/\\u00e2/, "â");
  gsub(/\\u00c2/, "Â");
}1' $PeopleMembership > temp && mv temp $PeopleMembership 

awk '/"personDisplayName"/ { gsub(/"/, ""); split($2, names, /[. ,]/); printf "%s,\n",names[1] }' $PeopleMembership > tempName && awk '/personEmail/ {gsub (/"|",/, "") ; print $2}' $PeopleMembership > email && paste tempName email | tr -d '\t' > csvWebinar.csv ; rm email tempName ; grep -vi 'cisco.com\|webex' csvWebinar.csv > tempWebinar ; mv tempWebinar csvWebinar.csv

mv $PeopleMembership archive_$PeopleMembership 

paste idMembers emailMember | tr -s " " | tr -d '\t' > idAndEmailMemberwithCisco_notuse

grep -ve 'cisco.com\|webex' idAndEmailMemberwithCisco_notuse > $idAndEmailMembers

cat emailMember | grep -ve 'cisco.com\|webex' | awk '{gsub(/"|,/, ""); print $2}'> $EmailMembersnoCisco

cat $EmailMembersnoCisco | awk 'BEGIN { FS="@" } {gsub(/,/, "") ; dominio = tolower($2); sum[dominio] += 1; } END { for (dominio in sum) { printf "%s: %d\n", dominio, sum[dominio]; }}' | sort -rn -k2,2 > $onlyDomainsNumberPeopleOverall

cat emailMember | awk '{gsub(/"|,/, ""); print $2}'> $EmailMemberswithCisco

cat listPublicEmailDomains | while read line; do grep -e "\@$line$" $EmailMembersnoCisco >> listEmailToBeDeletedfromExcel; done 

}

Messages() {

#Python script to pull messages
python roomActions.py GetMessages
file6MonthsMessages=`ls file6MonthsMessageRaw*` #file from python script

#Extracting all personEmail and created fields from last 2000 messages inside python script
grep -ie 'created\|personEmail' $file6MonthsMessages > $fileCreatedPersonEmailFieldRaw
mv $file6MonthsMessages archive_$file6MonthsMessages

#Extracting email and date people posted messsages from last 6 months
range="\(2023\-0[1-9]\|2023\-1[0-2]\|2024\-0[1-9]\)" ###MODIFY RANGE
grep -B1 'created.*'$range'' $fileCreatedPersonEmailFieldRaw > personEmailCreatedJun2023Dez2023

#Couting how many messages per people last period
grep personEmail personEmailCreatedJun2023Dez2023 | tr -s ' ' | cut -d' ' -f3 | sed -r 's/"(.*)"\,/\1/' | sort -u > $EmailwithActivity
grep personEmail personEmailCreatedJun2023Dez2023 | tr -s ' ' | cut -d' ' -f3 | sed -r 's/"(.*)"\,/\1/' | sort | uniq -c | sort -nr > $finalActivity 


#Use excel to sum the number of messages per channel
tr -s " "  < $finalActivity | sed -r 's/(\ .{1,}\ ).*@/\1/' |  sort -k2,2 | awk '{ domain = $2 ; sum[domain] += $1 } END {for (domain in sum) { printf "%d %s\n", sum[domain], domain}}' | sort -nr > $DomainsNumberMessages #AWK attempt

tr -s " "  < $finalActivity | sed -r 's/(\ .{1,}\ ).*@/\1/' | cut -d' ' -f3 | sort | uniq -c | sort -fdr > $DomainsNumberPeoplewithMessages 


#Extracting only domains last period
grep personEmail personEmailCreatedJun2023Dez2023 | sort -u | sed -r 's/.*@//; s/\"\,//' | sort -fdu > $onlyDomainsLast6Months
wc -l $onlyDomainsLast6Months > tempDomains; awk '{printf "\n\nTotal: %d\n", $1}' tempDomains >> $onlyDomainsLast6Months ; rm tempDomains 

#Users with no Activity
for i in `awk '{print $1}' $EmailMembersnoCisco`; do grep -i $i $finalActivity 1>/dev/null; [ $? -eq 0 ] && continue || echo $i >> $EmailnoActivity ; done

}

Deletion() {
#creating emails to be deleted from excel file "listEmailToBeDeletedfromExcel" and adding them to the file idMemberToBeDeleted.txt

for i in $(cat listEmailToBeDeletedfromExcel); do grep -i $i $idAndEmailMembers | cut -d' ' -f3 | sed -r 's/"(.*)"\,/\1/' >> $idMemberToBeDeleted ; done

python roomActions.py DelMembership $idMemberToBeDeleted

mv $idMemberToBeDeleted archive_$idMemberToBeDeleted
}


#pass a file with all emails you want to add points to
AddEmail() {
    while read line
    do 
	    python roomActions.py AddMembership $line
    done < $1
}

#pass a file with all emails you want to add points to
AddPoints() {
    while read line
    do 
        python roomActions.py AddPoints $line
        sleep 4
    done < $1
}

deactivate() {
	deactivate
}
clean() {
    Folder=$(date | awk '{printf "%s-%d-%d.%s",$2,$3,$NF,$4}')
    mkdir $Folder
	rm idMembers ; rm emailMember
	mv listEmailToBeDeletedfromExcel archive_listEmailToBeDeletedfromExcel
	touch listEmailToBeDeletedfromExcel
    mv {csv*,Domains*,archive*,fileCreated*,finalActivity*,idAndEmail*,onlyDomains*,personEmailCreated*,Email*} $Folder
}

#It has to start with Membership, then Messages.
if [[ $1 == 'Membership' ]]; then InitEnv; Membership; deactivate;
elif [[ $1 == 'Messages' ]]; then InitEnv; Messages; deactivate;
elif [[ $1 == 'Deletion' ]]; then InitEnv; Deletion; deactivate;
elif [[ $1 == 'AddEmail' ]]; then InitEnv; AddEmail $2; deactivate;
elif [[ $1 == 'AddPoints' ]]; then InitEnv; AddPoints $2; deactivate;
elif [[ $1 == 'Clean' ]]; then clean;
else echo "Unknown command";
fi

#git restore .
#git clean -f
