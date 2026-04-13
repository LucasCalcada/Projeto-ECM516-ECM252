import bcrypt from 'bcrypt';

export default async function hashPassword(password: string) {
  const salt = await bcrypt.genSalt();
  return bcrypt.hash(password, salt);
}
