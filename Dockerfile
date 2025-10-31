FROM node:22-bullseye-slim
WORKDIR /usr/src/app
COPY package*.json .
# RUN npm config set registry https://registry.npm.taobao.org && npm install
RUN npm install
COPY . .
EXPOSE 4000
CMD ["npm", "run", "server"]
