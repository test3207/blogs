FROM node:10
WORKDIR /usr/src/app
COPY . .
RUN npm install && npm install hexo -g
EXPOSE 4000
CMD ["hexo", "server"]
