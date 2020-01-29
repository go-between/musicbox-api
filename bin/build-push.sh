$(aws ecr get-login --no-include-email --region us-east-1)
docker build -t musicbox .
docker tag musicbox:latest 593337084109.dkr.ecr.us-east-1.amazonaws.com/musicbox:latest
docker push 593337084109.dkr.ecr.us-east-1.amazonaws.com/musicbox:latest
