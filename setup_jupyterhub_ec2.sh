# this script is largely based on this article about getting jupyterhub running on ec2 with docker: http://www.exegetic.biz/blog/2017/07/jupyter-docker-aws/
ssh ubuntu@ec2-34-229-15-217.compute-1.amazonaws.com -i ~/.ssh/first_key_josews.pem
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
# use docker without sudo: https://docs.docker.com/install/linux/linux-postinstall/
sudo groupadd docker
sudo usermod -aG docker $USER
docker run -d -p 8888:8000 jupyterhub/jupyterhub
http://ec2-34-229-15-217.compute-1.amazonaws.com/ 
# use jupyterhub without a password https://github.com/yuvipanda/jupyterhub-dummy-authenticator
sudo apt install python-pip -y
git clone https://github.com/jupyterhub/jupyterhub.git
cd jupyterhub
echo "c.JupyterHub.authenticator_class = 'dummyauthenticator.DummyAuthenticator'" >> jupyterhub_config.py
# note: had to remove jupyter_config.py from .dockerignore file for this to work
docker build . -t jh
docker run -d -p 80:8000 jh
# implement this: https://github.com/jupyterhub/jupyterhub-deploy-docker
# just notebook
# this works for running the graphing notebooks, though to do with SSL needed to create ACM certificate, real domain name, route through elastic load balancer (ELB), and tell ELB to use port 8888
docker run -d -p 8888:8888 jupyter/scipy-notebook
# generate SSL certificates
mkdir ssl
cd ssl
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out jupyter.crt -keyout jupyter.key
cd ..
docker run  -p 8888:8888 -v /home/ubuntu/ssl:/etc/ssl/notebook jupyter/scipy-notebook start-notebook.sh --NotebookApp.keyfile='/etc/ssl/notebook/jupyter.key' --NotebookApp.certfile='/etc/ssl/notebook/jupyter.crt' --NotebookApp.token= --NotebookApp.tornado_settings={'headers': {'Content-Security-Policy': "frame-ancestors *.armath.net *.squarespace.com 'self' "}}
# just run without docker
sudo apt install python3-pip ipython3 -y
pip3 install jupyter notebook scipy numpy matplotlib
sudo ipython3 kernel install
mkdir jupyter_reg
cd jupyter_reg
jupyter notebook --generate-config
echo "c.NotebookApp.keyfile = '/home/ubuntu/ssl/jupyter.key'" >> ../.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.certfile = '/home/ubuntu/ssl/jupyter.crt'" >> ../.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.token = u''" >> ../.jupyter/jupyter_notebook_config.py
# note: the echo statement below needs fixing because of the quotation mark stuff
echo "c.NotebookApp.tornado_settings = {'headers': {'Content-Security-Policy': "frame-ancestors *.armath.net *.squarespace.com 'self' "}}" >> ../.jupyter/jupyter_notebook_config.py
screen -S notebook
jupyter notebook --no-browser --ip=*
# custom docker
mkdir docker
cd docker/
# note: actually need to use special config file for docker
cp ../.jupyter/jupyter_notebook_config.py .
cp ../ssl . -rf
docker build -f Dockerfile.embed_jupyter -t embed_jupyter .
docker run -p 8888:8888 -t embed_jupyter
# try making not writeable: https://stackoverflow.com/questions/47022005/does-jupyter-support-read-only-notebooks?rq=1
sudo apt-get -y install awscli
aws configure
pip3 install awscli --upgrade --user
aws ecr get-login --no-include-email --region us-east-1 | bash
docker tag embed_jupyter:latest 914713380953.dkr.ecr.us-east-1.amazonaws.com/embed_jupyter:latest
docker push 914713380953.dkr.ecr.us-east-1.amazonaws.com/embed_jupyter 
# try for jupyterhub: https://github.com/jupyterhub/jupyterhub-deploy-docker
git clone https://github.com/mthmn20/graphing_notebooks.git
git clone https://github.com/jupyterhub/jupyterhub-deploy-docker.git
# get let's encrypt certificate using certbot
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot -y
sudo certbot certonly --standalone -d armathnotebooks.com -d www.armathnotebooks.com
cd jupyterhub-deploy-docker
echo "mthmn20 admin" >> userlist
mkdir secrets
cd secrets
sudo cp /etc/letsencrypt/live/armathnotebooks.com/fullchain.pem jupyterhub.crt
sudo cp /etc/letsencrypt/live/armathnotebooks.com/privkey.pem jupyterhub.key
vim oauth.env
cd ..
sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# tried to change Dockerfile.jupyterhub and jupyter_hub_config to not use certificates in secrets, but didn't work, ELB just not playing nice with this, so tried let's encrypt certs, that worked
cd ~/graphing_notebooks
git pull origin master
# if not a new volume and want to clean old one, run: docker system prune; docker volume rm -f jupyterhub-data
docker volume create --name jupyterhub-data
docker run -v jupyterhub-data:/data --name helper busybox true
docker cp /home/ubuntu/graphing_notebooks/. helper:/data
docker rm helper
# need to add notebook config file to singleuser for it to work when single user notebook servers are launched
cp ~/.jupyter/jupyter_notebook_config.py singleuser/
# tmpauthenticator to remove login requirement (probably just need this in dockerfile)
pip install jupyterhub-tmpauthenticator
# build and deploy commands (note: need to run the "docker volume" stuff if you make changes to default notebooks through git or something)
make build
# change .env file to look at scipy-notebook before this step
make notebook_image
docker-compose up -d
docker-compose down
# private certs 
# IMPORTANT NOTES:
#  - Congratulations! Your certificate and chain have been saved at:
#    /etc/letsencrypt/live/armathnotebooks.com/fullchain.pem
#    Your key file has been saved at:
#    /etc/letsencrypt/live/armathnotebooks.com/privkey.pem
#    Your cert will expire on 2018-11-07. To obtain a new or tweaked
#    version of this certificate in the future, simply run certbot
#    again. To non-interactively renew *all* of your certificates, run
#    "certbot renew"
