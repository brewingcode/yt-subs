FROM mhart/alpine-node:10

RUN apk add --no-cache --update tzdata yarn

WORKDIR /app
COPY package.json yarn.lock server.coffee ./
COPY src ./src
RUN yarn && yarn build

ENV TZ=America/Los_Angeles
EXPOSE 5000
ENV HOST 0.0.0.0
CMD ["./node_modules/.bin/coffee", "server.coffee"]
