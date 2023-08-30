'use strict';

import { MutationRootLoginArgs, getUserByEmail } from '@hasurify/graphql';
import { getResponse, APIGatewayEventExtended } from '@hasurify/lambda';
import { buildJWTToken } from '../../helpers';
import { ERROR_MESSAGES } from './constants';
import { BadRequestError, verifyPassword } from '@hasurify/util';

export async function loginHandler(event: APIGatewayEventExtended) {
  const {
    email,
    password,
    login_type: loginType,
  } = event.body.input as MutationRootLoginArgs;

  const user = await getUserByEmail(email);

  // User not found
  if (!user) {
    throw new BadRequestError(
      ERROR_MESSAGES.WRONG_INFO,
      400,
      'api:user.login_incorrect_email_or_password'
    );
  }

  // For now, we just allow login with email and password
  if (loginType === 'PASSWORD') {
    const passwordCorrect = await verifyPassword(password, user.password);
    if (!passwordCorrect) {
      throw new BadRequestError(
        ERROR_MESSAGES.WRONG_INFO,
        400,
        'api:user.login_incorrect_email_or_password'
      );
    }
  }

  // User not activated
  if (!user.is_active) {
    throw new BadRequestError(
      ERROR_MESSAGES.NOT_ACTIVE,
      400,
      'api:user.login_account_has_not_activated'
    );
  }

  // If password correct, render token
  const userRole = user.role && user.role.toUpperCase();
  const token = buildJWTToken(user.email, userRole, user.id);

  return getResponse({
    token,
  });
}
