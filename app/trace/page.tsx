"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import "../auth-trace.css";

type User = { user_id: number; email: string; role: string };
type BatchOption = { batch_id: number; batch_code: string; status: string; product: string };
type Upstream = {
  supplier_id: number; supplier: string; tier: number;
  material_id: number; material: string; lot: string; quantity_used: number;
};
type Downstream = {
  shipment_id: number; status: string; quantity: number;
  from_warehouse: string | null; dest_type: string | null; destination: string | null;
};
type SupplyChainRow = {
  direct_supplier_id: number; direct_supplier: string;
  supplier_id: number; supplier: string; tier: number | null;
  hops: number; path: string[];
};
type TraceResult = {
  batch_id: number; batch_code: string; status: string; depth?: number;
  upstream?: Upstream[]; supply_chain?: SupplyChainRow[]; downstream?: Downstream[];
};

export default function TracePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [batches, setBatches] = useState<BatchOption[]>([]);
  const [batchId, setBatchId] = useState("");
  const [direction, setDirection] = useState("both");
  const [depth, setDepth] = useState("3");
  const [result, setResult] = useState<TraceResult | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    async function init() {
      const me = await fetch("/api/auth/me");
      if (me.status === 401) {
        router.replace("/login");
        return;
      }
      const meData = await me.json();
      setUser(meData.user);

      const list = await fetch("/api/trace");
      if (list.ok) {
        const data: BatchOption[] = await list.json();
        setBatches(data);
        if (data.length > 0) setBatchId(String(data[0].batch_id));
      } else if (list.status === 403) {
        setError("Your role does not have access to batch tracing.");
      }
      setReady(true);
    }
    init().catch(() => {
      setError("Could not load the page. Please try again.");
      setReady(true);
    });
  }, [router]);

  async function runTrace() {
    setError("");
    setResult(null);
    setLoading(true);
    try {
      const response = await fetch(`/api/trace/${encodeURIComponent(batchId)}?direction=${direction}&depth=${depth}`);
      const data = await response.json();
      if (response.status === 401) {
        router.replace("/login");
        return;
      }
      if (!response.ok) {
        setError(data.error ?? "Trace failed");
        return;
      }
      setResult(data);
    } catch {
      setError("Could not run the trace. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.replace("/login");
  }

  if (!ready) {
    return (
      <main className="dashboard">
        <p className="message">Loading...</p>
      </main>
    );
  }

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SUPPLY CHAIN MANAGEMENT</p>
          <h1>Batch Traceability</h1>
          <p className="subtitle">
            Trace a batch upstream to its suppliers and downstream to every shipment and retailer.
          </p>
        </div>

        <div className="user-chip">
          {user && <span>{user.email} · {user.role}</span>}
          <a className="back-link" href="/">← Inventory Dashboard</a>
          <button className="ghost-btn" onClick={logout}>Sign out</button>
        </div>
      </header>

      <section className="warehouse-section">
        <div className="section-heading">
          <div>
            <h2>Run a trace</h2>
            <p>Choose a batch and direction. Data comes from the Neo4j graph.</p>
          </div>
        </div>

        <div className="trace-controls">
          <select value={batchId} onChange={(e) => setBatchId(e.target.value)} aria-label="Batch">
            {batches.map((b) => (
              <option key={b.batch_id} value={b.batch_id}>
                #{b.batch_id} · {b.batch_code} · {b.product} ({b.status})
              </option>
            ))}
          </select>

          <select value={direction} onChange={(e) => setDirection(e.target.value)} aria-label="Direction">
            <option value="both">Upstream + downstream</option>
            <option value="upstream">Upstream only</option>
            <option value="downstream">Downstream only</option>
          </select>

          <select value={depth} onChange={(e) => setDepth(e.target.value)} aria-label="Depth">
            {[1, 2, 3, 4, 5].map((d) => (
              <option key={d} value={d}>Sub-tier depth: {d}</option>
            ))}
          </select>

          <button className="primary-btn" onClick={runTrace} disabled={loading || !batchId}>
            {loading ? "Tracing..." : "Trace batch"}
          </button>
        </div>

        {error && <p className="error-message">{error}</p>}

        {result && (
          <>
            <p className="message">
              Batch <strong>{result.batch_code}</strong> · status <strong>{result.status}</strong>
            </p>

            {result.upstream && (
              <div className="trace-block">
                <h3>Upstream: contributing suppliers ({result.upstream.length})</h3>
                {result.upstream.length === 0 ? (
                  <p className="message">No upstream suppliers recorded for this batch.</p>
                ) : (
                  <table className="trace-table">
                    <thead>
                      <tr><th>Supplier</th><th>Tier</th><th>Material</th><th>Lot</th><th>Qty used</th></tr>
                    </thead>
                    <tbody>
                      {result.upstream.map((r) => (
                        <tr key={`${r.supplier_id}-${r.material_id}`}>
                          <td>{r.supplier}</td><td>{r.tier}</td><td>{r.material}</td>
                          <td>{r.lot}</td><td>{r.quantity_used}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}

            {result.supply_chain && (
              <div className="trace-block">
                <h3>Multi-tier: sub-tier suppliers up to {result.depth} levels ({result.supply_chain.length})</h3>
                {result.supply_chain.length === 0 ? (
                  <p className="message">No sub-tier suppliers recorded for this batch.</p>
                ) : (
                  <table className="trace-table">
                    <thead>
                      <tr><th>Supplier</th><th>Tier</th><th>Hops</th><th>Supply path</th></tr>
                    </thead>
                    <tbody>
                      {result.supply_chain.map((r, i) => (
                        <tr key={`${r.supplier_id}-${r.direct_supplier_id}-${i}`}>
                          <td>{r.supplier}</td><td>{r.tier ?? "-"}</td><td>{r.hops}</td>
                          <td>{r.path.join(" → ")}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}

            {result.downstream && (
              <div className="trace-block">
                <h3>Downstream: shipments and destinations ({result.downstream.length})</h3>
                {result.downstream.length === 0 ? (
                  <p className="message">This batch has not been shipped.</p>
                ) : (
                  <table className="trace-table">
                    <thead>
                      <tr><th>Shipment</th><th>Status</th><th>Qty</th><th>From</th><th>To</th></tr>
                    </thead>
                    <tbody>
                      {result.downstream.map((r) => (
                        <tr key={r.shipment_id}>
                          <td>#{r.shipment_id}</td><td>{r.status}</td><td>{r.quantity}</td>
                          <td>{r.from_warehouse ?? "-"}</td>
                          <td>{r.destination ? `${r.destination} (${r.dest_type})` : "-"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            )}
          </>
        )}
      </section>

      <footer className="dashboard-footer">
        Supply Chain Traceability System · Neo4j graph traversal
      </footer>
    </main>
  );
}
