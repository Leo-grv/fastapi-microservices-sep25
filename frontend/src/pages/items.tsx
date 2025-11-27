import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { apiItems } from "../lib/api";
import Nav from "../components/Nav";
import { useRouter } from "next/router";

type Item = { id: string; title: string; description?: string | null };

export default function Items() {
  const { token } = useAuth();
  const router = useRouter();
  const [items, setItems] = useState<Item[]>([]);
  const [title, setTitle] = useState("");

  useEffect(() => {
    if (!token) { router.replace("/"); return; }
    apiItems.get("/items/").then(res => setItems(res.data.data || []));
  }, [token]);

  const create = async () => {
    await apiItems.post("/items/", { title });
    const res = await apiItems.get("/items/");
    setItems(res.data.data || []);
    setTitle("");
  };

  return (
    <div style={{ display: "flex" }}>
      <Nav />
      <section style={{ padding: 24, width: "100%" }}>
        <h2>Items</h2>
        <div>
          <input placeholder="New item title" value={title} onChange={e => setTitle(e.target.value)} />
          <button onClick={create}>Create</button>
        </div>
        <ul>
          {items.map(i => <li key={i.id}>{i.title}</li>)}
        </ul>
      </section>
    </div>
  );
}
