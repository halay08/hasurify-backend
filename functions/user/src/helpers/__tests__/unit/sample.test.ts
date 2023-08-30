import { generateHashPassword, verifyPassword } from '../../user';

// Sample testcases
describe('TripPlan', () => {
  test('Should match the password with the hashed', async () => {
    const encryptedPassword = await generateHashPassword('123456Abcd@!');
    const isMatched = await verifyPassword('123456Abcd@!', encryptedPassword);
    const isNotMatched = await verifyPassword('123', encryptedPassword);

    expect(isMatched).toBe(true);
    expect(isNotMatched).toBe(false);
    //PASSED!
  });
});
