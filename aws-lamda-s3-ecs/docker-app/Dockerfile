FROM node:latest

RUN mkdir /app
COPY app.js /app/
COPY package.json /app/

WORKDIR /app
RUN npm install -g

ENTRYPOINT ["node", "app.js"]