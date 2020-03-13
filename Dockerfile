FROM mhart/alpine-node:10

RUN apk add --no-cache --update tzdata yarn git

WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn --ignore-engines
COPY src ./src
COPY server.coffee ./
RUN yarn build

ENV TZ=America/Los_Angeles
EXPOSE 5000
ENV HOST 0.0.0.0
CMD ["./node_modules/.bin/coffee", "server.coffee"]
