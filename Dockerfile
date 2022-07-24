FROM node:16-bullseye as client
RUN apt-get update && apt-get install -y openssl git rsync
WORKDIR /actual
ENV USER=partylich
ENV REPO=actual
ENV BRANCH=responsive
RUN git clone -b $BRANCH https://github.com/$USER/$REPO.git . && \
    yarn
ENV CI=true
RUN ./bin/package-browser

FROM node:16-bullseye as base
RUN apt-get update && apt-get install -y openssl git rsync
WORKDIR /app
ENV NODE_ENV=production
COPY --from=client /actual/packages/desktop-client/build/ /actual
COPY yarn.lock package.json ./
RUN npm rebuild bcrypt --build-from-source
RUN yarn install --production

FROM node:16-bullseye-slim as prod
RUN apt-get update && apt-get install -y openssl tini && apt-get clean -y && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=base /app /app
COPY --from=client /actual/packages/desktop-client/build/ /actual
COPY . .
ENTRYPOINT ["/usr/bin/tini","-g",  "--"]
CMD ["node", "app.js"]
