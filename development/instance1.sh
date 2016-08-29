#!/bin/bash

# Start/stop an EC2 instance to use as a ssh tunnel
# requires the aws package locally -- sudo apt-get install awscli
#
# usage: ./tunnel.sh start (spin up EC2 and create the tunnel)
#        ./tunnel.sh stop (terminate the EC2 instance to save money)
#        ./tunnel.sh resume (in case your tunnel is interrupted but the EC2 instance is still running)

# CHANGE THE PARAMETERS BELOW


imageid="ami-029cc768" # this is an Ubuntu AMI, but you can change it to whatever you want
instance_type="t2.medium"
count="1" # Number of instances to start 
security_group="sg-5ea4673a" # your security group -- http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html
wait_seconds="5" # seconds between polls for the public IP to populate (keeps it from hammering their API)
instanceprofile="itx-anv-app-springboard-development-1QJI45JUC76F5" # the IAM role to be attached before starting an instance


# END SETTINGS

# --------------------- you shouldn't have to change much below this ---------------------


# private
getip ()
{
	ip=$(aws ec2 describe-instances | grep PublicIpAddress | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
}

# public
start ()
{
	echo "Starting instance..."
	aws ec2 run-instances --image-id $imageid --count $count --instance-type $instance_type --iam-instance-profile Name="$instanceprofile"   --security-groups $security_group 

	# wait for a public ip
	while true; do

		echo "Waiting $wait_seconds seconds for IP..."
		sleep $wait_seconds
		getip
		if [ ! -z "$ip" ]; then
			break
		else
			echo "Not found yet. Waiting for $wait_seconds more seconds."
			sleep $wait_seconds
		fi

	done

	
}

# public
stop ()
{
	instance=$(aws ec2 describe-instances | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")

	aws ec2 terminate-instances --instance-ids $instance
}

# public
resume ()
{
	getip

}

# public
instruct ()
{
	echo "Please provide an argument: start, stop, resume"
}


#-------------------------------------------------------

# "main"
case "$1" in
	start)
		start
		;;
	resume)
		resume
		;;
	stop)
		stop
		;;
	help|*)
		instruct
		;;
esac