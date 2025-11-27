import React, { createContext, useContext, useEffect, useState } from "react";
import { apiAuth, apiUsers } from "../lib/api";

type User = {
  id: string;
  email: string;
  full_name?: string | null;
  is_superuser: boolean;
  is_active: boolean;
};

type AuthContextType = {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthCtx = createContext<AuthContextType | null>(null);

export const AuthProvider: React.FC<React.PropsWithChildren> = ({ children }) => {
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);

  const loadMe = async (tok: string) => {
    const res = await apiUsers.get("/users/me", {
      headers: { Authorization: `Bearer ${tok}` },
    });
    setUser(res.data);
  };

  const login = async (email: string, password: string) => {
    const body = new URLSearchParams();
    body.append("username", email);
    body.append("password", password);

    const res = await apiAuth.post("/login/access-token", body);
    const access = res.data?.access_token;
    localStorage.setItem("token", access);
    setToken(access);
    await loadMe(access);
  };

  const logout = () => {
    localStorage.removeItem("token");
    setUser(null);
    setToken(null);
  };

  useEffect(() => {
    const existing = localStorage.getItem("token");
    if (existing) {
      setToken(existing);
      loadMe(existing).catch(() => logout());
    }
  }, []);

  return (
    <AuthCtx.Provider value={{ user, token, login, logout }}>
      {children}
    </AuthCtx.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
