FROM node:16-bullseye as base
RUN apt-get update && apt-get install -y openssl git rsync
WORKDIR /actual
RUN git clone -b responsive https://github.com/partylich/actual.git .
RUN yarn
RUN CI=true ./bin/package-browser
WORKDIR /app
ENV NODE_ENV=production
COPY yarn.lock package.json ./
RUN npm rebuild bcrypt --build-from-source && \
    yarn install --production

FROM node:16-bullseye-slim as prod
RUN apt-get update && apt-get install -y openssl tini && apt-get clean -y && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=base /app /app
COPY --from=base /actual/packages/desktop-client/build/ /actual
COPY . .
ENTRYPOINT ["/usr/bin/tini","-g",  "--"]
CMD ["node", "app.js"]
