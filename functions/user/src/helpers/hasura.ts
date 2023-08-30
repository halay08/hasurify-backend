import jwt from 'jsonwebtoken';

export const buildJWTToken = (
  email: string,
  userRole: string,
  userId?: number
): string => {
  // If password correct, render token
  const { HASURA_JWT_SECRET: hasuraSecret = '' } = process.env;

  const payload = {
    'https://hasura.io/jwt/claims': {
      'x-hasura-allowed-roles': [userRole],
      'x-hasura-default-role': userRole,
      'x-hasura-user-id': userId && userId.toString(),
      'x-hasura-user-email': email,
    },
  };
  const token = jwt.sign(payload, hasuraSecret?.trim());

  return token;
};
