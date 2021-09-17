FROM node:12-alpine
WORKDIR /usr/src/app
COPY . .
RUN npm config set registry https://registry.npm.taobao.org && npm install
EXPOSE 4000
CMD ["npm", "run", "server"]
