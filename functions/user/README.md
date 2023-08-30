# Serverless Framework for User service

## Getting Started

Get started with Serverless Framework’s open-source CLI and AWS in minutes [here](https://www.serverless.com/framework/docs/getting-started).

## Development

```sh
$ cd functions/user
$ cp secrets.dev.yml.example secrets.dev.yml
$ cp .npmrc.example .npmrc # Please change your npm token
$ docker-compose up -d --build
```

## Deployment

Decrypt secret file

```sh
$ cd functions/service
$ serverless decrypt --stage dev --password 'hasurify@nonesec123'
$ yarn deploy:dev
```

## Troubleshooting
