import express from 'express';
import bcrypt from 'bcrypt';
import cors from 'cors';
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

app.post('/users', async(req, res) => {
  try {
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    const user: User = { username: req.body.username, password: hashedPassword };
    users.push(user);
    res.status(201).send();
  } catch {
    res.status(500).send();
  }
});

app.post('/login', async(req, res) => {
    const user = users.find(user => user.username === req.body.username);
    if (user == null) {
        return res.status(400).send('Usuário não encontrado');
    }
    try {        
        if (await bcrypt.compare(req.body.password, user.password)) {
            res.status(200).send('Sucesso');
        } else {
            res.status(400).send('Senha incorreta');
        }
    } catch {
        res.status(500).send();
    }
});
app.listen(3000);