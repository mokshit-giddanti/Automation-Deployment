#!/bin/bash

# Update the package index
sudo apt-get update -y

# Install necessary packages
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again
sudo apt-get update -y

# Install Docker Engine, CLI, containerd, and Docker Compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service and enable it to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Define variables
APP_DIR="/home/ubuntu/webapp"
GITHUB_REPO_URL="${github_repo_url}"
DOCKER_IMAGE_NAME="my-webapp"
DOCKER_CONTAINER_NAME="my-webapp"

# Ensure the app directory has the correct permissions
sudo chmod -R 755 /home/ubuntu/webapp
sudo chown -R ubuntu:ubuntu /home/ubuntu/webapp

# Clone the GitHub repository
if [ -d "$APP_DIR" ]; then
    echo "Repository already exists. Pulling latest changes."
    cd "$APP_DIR" && sudo git pull
else
    echo "Cloning repository."
    sudo git clone $GITHUB_REPO_URL $APP_DIR
fi

# Navigate to the application directory
cd $APP_DIR

# Check if the frontend folder exists and navigate into it if it does
if [ -d "frontend" ]; then
    cd frontend
fi

# Remove existing node_modules if it exists
if [ -d "node_modules" ]; then
    echo "Removing existing node_modules directory."
    sudo rm -rf node_modules
fi

# Create Dockerfile for React application with multi-stage build
sudo bash -c 'cat <<EOF > Dockerfile
FROM node:18 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF'

# Build the Docker image
sudo docker build -t $DOCKER_IMAGE_NAME .

# Stop and remove any existing container
if sudo docker ps -q -f name=$DOCKER_CONTAINER_NAME; then
    sudo docker stop $DOCKER_CONTAINER_NAME
    sudo docker rm $DOCKER_CONTAINER_NAME
fi

# Run the Docker container
sudo docker run -d -p 80:80 --name $DOCKER_CONTAINER_NAME $DOCKER_IMAGE_NAME

# Get the public IP of the instance
public_ip=$(curl -s ifconfig.me)

# Output the deployment details to a file
echo "Deployment completed. Access the app at http://$public_ip" | sudo tee /home/ubuntu/deployment_info.txt
