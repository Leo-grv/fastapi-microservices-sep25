import { FormEvent, useState } from "react";
import { useRouter } from "next/router";
import { useAuth } from "../context/AuthContext";

export default function Login() {
  const { login, token } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("admin@test.com");
  const [password, setPassword] = useState("Test123!");
  const [err, setErr] = useState("");

  if (token) router.replace("/dashboard");

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setErr("");
    try {
      await login(email, password);
      router.push("/dashboard");
    } catch {
      setErr("Invalid credentials");
    }
  };

  return (
    <main style={{ display: "grid", placeItems: "center", height: "100vh" }}>
      <form onSubmit={onSubmit} style={{ width: 320 }}>
        <h2>Login</h2>
        {err && <p style={{ color: "red" }}>{err}</p>}
        <input value={email} onChange={e => setEmail(e.target.value)} placeholder="Email" style={{ width: "100%", marginBottom: 8 }} />
        <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" style={{ width: "100%", marginBottom: 8 }} />
        <button type="submit" style={{ width: "100%" }}>Sign in</button>
      </form>
    </main>
  );
}
