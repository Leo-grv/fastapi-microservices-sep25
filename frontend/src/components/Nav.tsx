import Link from "next/link";
import { useAuth } from "../context/AuthContext";

export default function Nav() {
  const { user, logout } = useAuth();
  return (
    <aside style={{ width: 220, padding: 16, background: "#f4f7fa", height: "100vh" }}>
      <h3>FastAPI</h3>
      <ul style={{ listStyle: "none", padding: 0 }}>
        <li><Link href="/dashboard">Dashboard</Link></li>
        <li><Link href="/items">Items</Link></li>
        <li><Link href="/admin">Admin</Link></li>
      </ul>
      <div style={{ position: "absolute", bottom: 16 }}>
        <div>Logged in as:<br /> {user?.email}</div>
        <button onClick={logout} style={{ marginTop: 8 }}>Logout</button>
      </div>
    </aside>
  );
}
