# FROM node :Base image for the application(Image for Node.js.)
FROM node

# Define the working directory of Docker container
WORKDIR /apps/one2onetool

# Define ENV variables
ENV PORT 8082
# expect a build-time variable
ARG DATA_FILE_VAR
# use the value to set the ENV var default
ENV DATA_FILE=$DATA_FILE_VAR

# Install app dependencies
COPY package*.json ./

RUN npm install

# Bundle app source
COPY . .

EXPOSE 8082
CMD [ "npm", "start" ]
