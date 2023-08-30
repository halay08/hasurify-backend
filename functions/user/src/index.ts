import {
  loginHandler,
  authorizationHandler,
  createUserHandler,
} from './functions';
import { getHandler } from '@hasurify/lambda';

const login = getHandler(loginHandler);
const authorize = getHandler(authorizationHandler);
const createUser = getHandler(createUserHandler);

export { login, authorize, createUser };
