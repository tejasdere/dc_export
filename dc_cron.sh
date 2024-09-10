cd /siemens/openjdk
java_version=$(ls | head -n 1)
export JAVA_HOME=/siemens/openjdk/$java_version

dc_status=$(/siemens/DeploymentCenter/webserver/dcserver.sh status)
substring="not running"

if [[ $dc_status == *"$substring"* ]]; then
    echo "Substring '$substring' exists"
	/siemens/DeploymentCenter/webserver/dcserver.sh start
	/siemens/DeploymentCenter/webserver/repotool/repotool.sh start
	/siemens/DeploymentCenter/webserver/messaging/publisher.sh start
else
    echo "DC is running"
fi

cd /siemens/DeploymentCenter/webserver/additional_tools/internal/dc_quick_deploy
input=$(hostname)
pattern="tcs"
custID=$(echo "$input" | sed "s/$pattern.*//")
suffix=$(echo "$input" | sed "s/.*tcs1p//")

# Check if suffix contains a number
if [[ $suffix =~ [0-9]+$ ]]; then
    finalSuffix="prd$suffix"                      # If suffix contains numbers, append them to "prd"
else
    finalSuffix="prd"                             # If no number, just set it as "prd"
fi

interface="eth0"
ip_address=$(ip addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
dcURL="http://$ip_address:8094/deploymentcenter"

./dc_quick_deploy.sh -dcurl=$dcURL -mode=export -environment=$finalSuffix-$custID -exportType=Full -exportfile=/siemens/dc_export/dc_export.xml -dcusername=dcadmin -dcpassword=password -preservedeploymentstatus

cd /siemens/dc_export/
tr -d '\n' < dc_export.xml > dc_export_1line.xml

if [[ $dc_status == *"$substring"* ]]; then
    echo "Substring '$substring' exists"
	/siemens/DeploymentCenter/webserver/dcserver.sh stop
	/siemens/DeploymentCenter/webserver/repotool/repotool.sh stop
	/siemens/DeploymentCenter/webserver/messaging/publisher.sh stop
else
    echo "Leave DC running"
fi
