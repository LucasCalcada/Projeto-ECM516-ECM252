import React, { useState } from "react";
// Importamos os componentes que acabamos de criar
import Logo from "./Logo";
import TextField from "./TextField";
import Button from "./Button";

export default function LoginBox() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log("Tentativa de login:", { username, password });
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-neutral-800">
      <Logo />

      <div className="bg-neutral-800 p-10 rounded-lg  w-full max-w-sm">
        <h2 className="text-2xl font-bold text-center text-neutral-100 mb-8">
          Login
        </h2>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <TextField
            id="username"
            label="Usuário"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Digite seu usuário"
          />

          <TextField
            id="password"
            label="Senha"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Digite sua senha"
          />

          <Button text="Entrar" />
        </form>
      </div>
    </div>
  );
}

