import {
  getResponse,
  APIGatewayEventExtended,
  appLogger,
} from '@hasurify/lambda';
import { upsertUser } from '@hasurify/graphql';
import { generateHashPassword } from '@hasurify/util';

export async function createUserHandler(event: APIGatewayEventExtended) {
  const { password } = event.body.input.input || {};
  const payload = event.body.input.input;

  // If insert or update User with new password
  if (password) {
    payload.password = await generateHashPassword(password);
  }

  const user = await upsertUser(payload);

  return getResponse({ id: user?.id });
}
