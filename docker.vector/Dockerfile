FROM node:latest
WORKDIR /usr/src/app

COPY package*.json ./
COPY src/ .
RUN npm install

RUN npm install -g vector-web-setup
RUN vector-web-setup configure
RUN vector-web-setup ota-sync
ENV PORT 8000
EXPOSE 8000
CMD vector-web-setup serve -p $PORT



