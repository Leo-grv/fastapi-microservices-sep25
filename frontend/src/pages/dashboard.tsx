import { useAuth } from "../context/AuthContext";
import { useRouter } from "next/router";
import Nav from "../components/Nav";

export default function Dashboard() {
  const { user, token } = useAuth();
  const router = useRouter();
  if (!token) {
    if (typeof window !== "undefined") router.replace("/");
    return null;
  }
  return (
    <div style={{ display: "flex" }}>
      <Nav />
      <section style={{ padding: 24, width: "100%" }}>
        <h2>User Management</h2>
        {user ? (
          <pre>{JSON.stringify(user, null, 2)}</pre>
        ) : (
          <p>Loading…</p>
        )}
      </section>
    </div>
  );
}
