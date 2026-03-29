import React, { useState } from "react";
import Logo from "./Logo";
import TextField from "./TextField";
import Button from "./Button";
import { useNavigate } from "react-router";
import { useTranslation } from "react-i18next";

export default function LoginBox() {
  const { t } = useTranslation();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log("Tentativa de login:", { username, password });
    navigate("/home", { replace: true });
  };

  return (
    <div className="w-full min-h-screen flex flex-col items-center justify-center bg-neutral-800">
      <Logo />

      <div className="bg-neutral-800 p-10 rounded-lg  w-full max-w-sm">
        <h2 className="text-2xl font-bold text-center text-neutral-100 mb-8">
          Login
        </h2>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <TextField
            id="username"
            label={t("login.fields.username.label")}
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder={t("login.fields.username.placeholder")}
          />

          <TextField
            id="password"
            label={t("login.fields.password.label")}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={t("login.fields.password.placeholder")}
          />

          <Button text={t("login.login")} />
        </form>
      </div>
    </div>
  );
}
