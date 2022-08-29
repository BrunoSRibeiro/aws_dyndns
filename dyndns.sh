#!/bin/bash
IP=$(dig +short SOME_DYNAMIC_DNS_DOMAIN)
SG_ID="SECURITY_GROUP_ID"
PROFILE_ID="AWS_CLI_PROFILE_ID"
prot="SOME_PROTOCOL_LIKE_TCP_OR_UDP"
prt="SERVICE_PORT"

aws ec2 describe-security-groups --output json --group-id $SG_ID --query "SecurityGroups[0].IpPermissions" --profile $PROFILE_ID | grep $IP >/dev/null

if [ $? -eq 0 ]
then
        exit 0
else
        RULE_SSH=$(aws ec2 describe-security-groups --output json --group-id $SG_ID --query "SecurityGroups[0].IpPermissions" --profile $PROFILE_ID | grep -A 5 '"FromPort": $prt')
        if [ $? -eq 0 ]
        then
                OLD_IP=$(echo "$RULE_SSH" | grep CidrIp | awk '{print $2}' | sed 's/"//g')
                aws ec2 revoke-security-group-ingress --group-id $SG_ID --protocol $prot --port $prt --cidr $OLD_IP --profile=$PROFILE_ID
                aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol $prot --port $prt --cidr $IP/32 --profile=$PROFILE_ID
        else
                aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol $prot --port $prt --cidr $IP/32 --profile=$PROFILE_ID
        exit 1
        fi
fi