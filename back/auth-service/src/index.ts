import express from 'express';
import bcrypt from 'bcrypt';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '.env') });

const app = express();
app.use(cors());
app.use(express.json());
interface User {
  username: string;
  password: string;
}
const users: User[] = [];

app.get('/users', (req, res) => {
  res.json(users);
});

app.post('/users', async (req, res) => {
  try {
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    const user: User = { username: req.body.username, password: hashedPassword };
    users.push(user);
    res.status(201).send();
  } catch {
    res.status(500).send();
  }
});

app.post('/login', async (req, res) => {
  const user = users.find((user) => user.username === req.body.username);
  if (user == null) {
    return res.status(400).send('Credenciais inválidas');
  }
  try {
    if (await bcrypt.compare(req.body.password, user.password)) {
      const token = jwt.sign(
        { username: user.username },
        process.env.JWT_ACCESS_TOKEN_SECRET as string,
        { expiresIn: '1h' },
      );
      res.status(200).json({ accessToken: token });
    } else {
      res.status(400).send('Credenciais inválidas');
    }
  } catch {
    res.status(500).send();
  }
});
app.get('/protected', authToken, (req, res) => {
  res.json({ message: 'Acesso permitido' });
});

function authToken(req: express.Request, res: express.Response, next: express.NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) return res.status(401).send('Acesso negado');
  jwt.verify(token, process.env.JWT_ACCESS_TOKEN_SECRET as string, (err, user) => {
    if (err) return res.status(403).send('Acesso negado');
    next();
  });
}
app.listen(3000);

