# implement this tutorial: https://zero-to-jupyterhub.readthedocs.io/en/latest/amazon/step-zero-aws.html 
# run using the bitnami kubernetes AMI: bitnami-kubernetessandbox-1.10.5-0-linux-ubuntu-16.04-x86_64-hvm-eb-28b0b6c7-a946-4382-b421-22c9c953a68d-ami-070c6364badb7fe32.4 (ami-3448784b)
ssh ubuntu@ec2-52-90-149-11.compute-1.amazonaws.com -i ~/.ssh/first_key_josews.pem
# install kops
wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x ./kops
sudo mv ./kops /usr/local/bin/
# install awscli
sudo apt-get update
sudo apt-get -y install awscli
aws configure
ssh-keygen
export NAME=armathnotebooks.com
export KOPS_STATE_STORE=s3://jupyterhub-kubernetes-config
export REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`
export REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`

export ZONES=$(aws ec2 describe-availability-zones --region $REGION | grep ZoneName | awk '{print $2}' | tr -d '"')
export ZONES=$(echo $ZONES | tr -d " " | rev | cut -c 2- | rev)
kops create cluster $NAME --zones $ZONES --authorization RBAC --master-size t2.medium --master-volume-size 10 --node-size t2.medium --node-volume-size 10 --topology private --networking weave --node-count 1 --yes
# domain stuff, may run once for each subdomain (e.g. kube), though appears like kops automatically creates some record sets in hosted zone for appropriate domain, though looks like still need to create NS record set for the main subdomain as per: https://kubernetes.io/docs/setup/custom-cloud/kops/#2-5-create-a-route53-domain-for-your-cluster 
# aws route53 create-hosted-zone --name cluster.armathnotebooks.com --caller-reference 1