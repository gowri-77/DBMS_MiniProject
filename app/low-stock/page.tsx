"use client";

import { useEffect, useState } from "react";

type LowStockItem = {
  warehouse: string;
  batch_code: string;
  product: string;
  quantity: number;
};

export default function LowStockPage() {
  const [items, setItems] = useState<LowStockItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadLowStock() {
      try {
        const response = await fetch("/api/low-stock");

        if (!response.ok) {
          throw new Error("Unable to load low-stock data");
        }

        const data: LowStockItem[] = await response.json();
        setItems(data);
      } catch {
        setError("Could not load low-stock data. Please try again.");
      } finally {
        setLoading(false);
      }
    }

    loadLowStock();
  }, []);

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SUPPLY CHAIN MANAGEMENT</p>
          <h1>Low-Stock Alerts</h1>
          <p className="subtitle">
            Review inventory records identified by your database view.
          </p>
        </div>

        <a className="back-link" href="/">
          ← Inventory Dashboard
        </a>
      </header>

      <section className="warehouse-section">
        <div className="section-heading">
          <div>
            <h2>Inventory Requiring Attention</h2>
            <p>Stock records grouped by warehouse and batch</p>
          </div>

          <span className="record-count">{items.length} records</span>
        </div>

        {loading && <p className="message">Loading inventory...</p>}

        {error && <p className="error-message">{error}</p>}

        {!loading && !error && items.length === 0 && (
          <p className="message">No records were returned by the low-stock view.</p>
        )}

        {!loading && !error && items.length > 0 && (
          <div className="table-container">
            <table className="inventory-table">
	    <colgroup>
  		<col style={{ width: "28%" }} />
  		<col style={{ width: "32%" }} />
  		<col style={{ width: "22%" }} />
  		<col style={{ width: "18%" }} />
	    </colgroup>
              <thead>
                <tr>
                  <th>Warehouse</th>
                  <th>Product</th>
                  <th>Batch Code</th>
                  <th>Quantity</th>
                </tr>
              </thead>

              <tbody>
                {items.map((item, index) => (
                  <tr key={`${item.batch_code}-${item.warehouse}-${index}`}>
                    <td>{item.warehouse}</td>
                    <td className="product-name">{item.product}</td>
                    <td>
                      <span className="batch-code">{item.batch_code}</span>
                    </td>
                    <td>
                      <strong>{Number(item.quantity).toLocaleString("en-IN")}</strong>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <footer className="dashboard-footer">
        Supply Chain Traceability System · Live PostgreSQL data
      </footer>
    </main>
  );
}