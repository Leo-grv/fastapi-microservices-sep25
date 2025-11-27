import axios from "axios";

// IMPORTANT : on passe par le gateway Traefik.
// Exemple: NEXT_PUBLIC_API_BASE = "http://172.31.38.131"
const API_BASE = process.env.NEXT_PUBLIC_API_BASE || "http://localhost";

export const apiAuth = axios.create({
  baseURL: `${API_BASE}/auth/api/v1`,
});
export const apiUsers = axios.create({
  baseURL: `${API_BASE}/users/api/v1`,
});
export const apiItems = axios.create({
  baseURL: `${API_BASE}/items/api/v1`,
});

// Attache automatiquement le token si présent
function attachToken(instance: typeof apiAuth) {
  instance.interceptors.request.use((config) => {
    const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  });
}
[apiUsers, apiItems].forEach(attachToken);

export { API_BASE };
