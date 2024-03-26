#!/bin/bash 

# This script creates EC2 Instaces & the associated DNS Records for the created servers

AMI_ID="ami-072983368f2a6eab5"
SGID="sg-0ac43e71879aa54f5"               # Create your own Security Group that allows allows all and then add your SGID 
HOSTEDZONE_ID="Z0198314A9R9W86DTX4S"     # User your private zone id
COMPONENT=$1
ENV=$2
COLOR="\e[35m"
NOCOLOR="\e[0m"

if [ -z $1 ] || [ -z $2 ] ; then
    echo -e "\e[31m   COMPONENT & ENV ARE NEEDED: \e[0m"
    echo -e "\e[36m \t\t Example Usage : \e[0m  bash launch-ec2 dev ratings"
    exit 1
fi 

create_ec2() {
    PRIVATE_IP=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SGID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}-${ENV}}]" | jq .Instances[].PrivateIpAddress |sed -e 's/"//g')
    echo -e "___ $COLOR $1-$2 Server Created and here is the IP ADDRESS $PRIVATE_IP $NOCOLOR ___"

    echo "Creating r53 json file with component name and ip address:"
    sed -e "s/IPADDRESS/${PRIVATE_IP}/g" -e "s/COMPONENT/${COMPONENT}-${ENV}/g" route53.json  > /tmp/dns.json 

    echo -e "___ $COLOR Creating DNS Record for $COMPONENT-${ENV} ___ $NOCOLOR \n\n"
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTEDZONE_ID --change-batch file:///tmp/dns.json 
}

# if component name from user is all, then I would like create & update all 10 servers and it's DNS Records 
if [ "$1" == "all" ]; then 
    for comp in frontend mongodb catalogue user redis cart mysql shipping rabbimq payment; do 
        COMPONENT=$comp
        create_ec2
    done
else  
    create_ec2
fi
