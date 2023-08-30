FROM halay08/sls-node:18-alpine

ENV NODE_OPTIONS=--max_old_space_size=8192

WORKDIR /home/app

RUN yarn global add serverless

USER root

COPY package.json tsconfig.json yarn.lock serverless.yml secrets.dev.yml .npmrc ./
RUN yarn install --ignore-scripts

USER node

CMD ["yarn", "dev"]