import axios from "axios";

// PROD: Tout passe par le même domaine sans ports
const getBaseUrl = () => {
  if (typeof window === "undefined") return "";
  const { protocol, hostname } = window.location;
  return `${protocol}//${hostname}/api/v1`;
};

// Créer les instances axios
export const apiAuth = axios.create();
export const apiUsers = axios.create();
export const apiItems = axios.create();

// Helper pour créer un interceptor
const createInterceptor = () => {
  return (config: any) => {
    if (config.url?.startsWith("/")) {
      config.url = getBaseUrl() + config.url;
    }
    
    // Attacher le token si présent
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("token");
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    
    return config;
  };
};

// Appliquer les interceptors
apiAuth.interceptors.request.use(createInterceptor());
apiUsers.interceptors.request.use(createInterceptor());
apiItems.interceptors.request.use(createInterceptor());