docker_securitymonkey
=====================

Security Monkey with Docker

TO Install Security Monkey on an EC2 instance

- Launch an EC2 instance with Amazon Linux AMI
-- sudo yum install -y docker
-- sudo service docker start

- Download securitymonkey repo from docker
-- sudo docker pull nagwww/securitymonkey

- Install SecurityMonkey as
--  sudo docker run -e "mail=nagwww@gmail.com" -e "host=ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com" -i -t -p 443:443 -p 5000:5000 "nagwww/securitymonkey:v2" /home/ubuntu/securitymonkey.sh

- Create a new user as
-- monkey create_user "awsalerter@gmail.com" "Admin"

To build a Docker image
- Change the Dockerfile as needed

- Build the image as
--  docker build -t "nagwww/securitymonkey:v1" .

- Push the image to Docker as
-- docker push nagwww/securitymonkey
