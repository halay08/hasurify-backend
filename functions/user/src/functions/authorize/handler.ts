'use strict';

import jwt from 'jsonwebtoken';
import {
  getResponse,
  APIGatewayEventExtended,
  appLogger,
} from '@hasurify/lambda';
import { getUser } from '@hasurify/graphql';

export async function authorizationHandler(event: APIGatewayEventExtended) {
  let authorization = '';
  if (event.httpMethod === 'POST') {
    authorization =
      event.body.headers['authorization'] ||
      event.body.headers['Authorization'];
  } else {
    authorization =
      event.headers['authorization'] || event.headers['Authorization'];
  }

  if (authorization) {
    try {
      const token = authorization.split(' ')[1];
      if (token !== null && token !== 'null') {
        const { HASURA_JWT_SECRET: hasuraSecret = '' } = process.env;

        const decoded = jwt.verify(token.trim(), hasuraSecret?.trim());

        const userEmail =
          decoded['https://hasura.io/jwt/claims']['x-hasura-user-email'];
        const userRole =
          decoded['https://hasura.io/jwt/claims']['x-hasura-default-role'];
        const userId =
          decoded['https://hasura.io/jwt/claims']['x-hasura-user-id'];

        if (userId) {
          const user = await getUser(parseInt(userId));

          return getResponse({
            'X-Hasura-Role': userRole,
            'X-Hasura-User-Id': user.id.toString(),
            'X-Hasura-User-Email': userEmail,
          });
        }
      }
    } catch ({ message }) {
      appLogger.error(message as string);
      return getResponse({}, 401);
    }
  }

  return getResponse({
    'X-Hasura-Role': 'anonymous',
  });
}
