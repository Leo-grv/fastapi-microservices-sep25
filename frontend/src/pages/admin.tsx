import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { apiUsers } from "../lib/api";
import Nav from "../components/Nav";
import { useRouter } from "next/router";

type User = { id: string; email: string; full_name?: string | null; is_superuser: boolean; is_active: boolean };

export default function Admin() {
  const { user, token } = useAuth();
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);

  useEffect(() => {
    if (!token) { router.replace("/"); return; }
    apiUsers.get("/users/").then(res => setUsers(res.data.data || []))
      .catch(() => setUsers([]));
  }, [token]);

  if (!user?.is_superuser) {
    return (
      <div style={{ display: "flex" }}>
        <Nav />
        <section style={{ padding: 24, width: "100%" }}>
          <h2>Admin</h2>
          <p>Not enough privileges.</p>
        </section>
      </div>
    );
  }

  return (
    <div style={{ display: "flex" }}>
      <Nav />
      <section style={{ padding: 24, width: "100%" }}>
        <h2>User Management</h2>
        <table>
          <thead><tr><th>Full Name</th><th>Email</th><th>Role</th><th>Status</th></tr></thead>
          <tbody>
            {users.map(u => (
              <tr key={u.id}>
                <td>{u.full_name || "N/A"}</td>
                <td>{u.email}</td>
                <td>{u.is_superuser ? "Superuser" : "User"}</td>
                <td>{u.is_active ? "Active" : "Inactive"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}
