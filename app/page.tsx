"use client";

import { useEffect, useState } from "react";

type Warehouse = {
  warehouse_id: number;
  name: string;
  city: string;
  state: string;
  capacity: number;
  units_in_stock: string;
  batches_held: string;
  utilisation_pct: string;
};

export default function Home() {
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadWarehouses() {
      try {
        const response = await fetch("/api/warehouses");

        if (!response.ok) {
          throw new Error("Unable to load warehouse inventory.");
        }

        const data: Warehouse[] = await response.json();
        setWarehouses(data);
      } catch {
        setError("Could not load inventory. Please try again.");
      } finally {
        setLoading(false);
      }
    }

    loadWarehouses();
  }, []);

  const totalStock = warehouses.reduce(
    (sum, warehouse) => sum + Number(warehouse.units_in_stock),
    0
  );

  const totalBatches = warehouses.reduce(
    (sum, warehouse) => sum + Number(warehouse.batches_held),
    0
  );

  const totalCapacity = warehouses.reduce(
    (sum, warehouse) => sum + Number(warehouse.capacity),
    0
  );

  const utilisation =
    totalCapacity > 0
      ? ((totalStock / totalCapacity) * 100).toFixed(1)
      : "0.0";

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SUPPLY CHAIN MANAGEMENT</p>
          <h1>Inventory Dashboard</h1>
          <p className="subtitle">
            Monitor stock levels across your distribution network.
          </p>
        </div>

        <div className="connection-status">
          <span className="status-dot" />
          PostgreSQL connected
        </div>
	<a className="back-link" href="/batches">
 		View Batches →
	</a>
	<a className="back-link" href="/low-stock">
  		View Low Stock →
	</a>

	<a className="back-link" href="/orders">
  		View Orders →
	</a>
      </header>

      {loading && <p className="message">Loading inventory...</p>}

      {error && <p className="error-message">{error}</p>}

      {!loading && !error && (
        <>
          <section className="summary-grid">
            <article className="summary-card">
              <p>Total Warehouses</p>
              <h2>{warehouses.length}</h2>
              <span>Across the distribution network</span>
            </article>

            <article className="summary-card">
              <p>Units in Stock</p>
              <h2>{totalStock.toLocaleString("en-IN")}</h2>
              <span>Units currently recorded</span>
            </article>

            <article className="summary-card">
              <p>Batches Held</p>
              <h2>{totalBatches}</h2>
              <span>Across all warehouses</span>
            </article>

            <article className="summary-card">
              <p>Overall Utilisation</p>
              <h2>{utilisation}%</h2>
              <span>Stock compared with total capacity</span>
            </article>
          </section>

          <section className="warehouse-section">
            <div className="section-heading">
              <div>
                <h2>Warehouse Overview</h2>
                <p>Stock and capacity by location</p>
              </div>
              <span className="record-count">
                {warehouses.length} locations
              </span>
            </div>

            <div className="warehouse-grid">
              {warehouses.map((warehouse) => {
                const percentage = Math.min(
                  100,
                  Math.max(0, Number(warehouse.utilisation_pct) || 0)
                );

                return (
                  <article
                    className="warehouse-card"
                    key={warehouse.warehouse_id}
                  >
                    <div className="warehouse-top">
                      <div>
                        <p className="location">
                          {warehouse.city}, {warehouse.state}
                        </p>
                        <h3>{warehouse.name}</h3>
                      </div>

                      <span className="warehouse-icon">WH</span>
                    </div>

                    <div className="stock-row">
                      <span>Units in stock</span>
                      <strong>
                        {Number(warehouse.units_in_stock).toLocaleString(
                          "en-IN"
                        )}
                      </strong>
                    </div>

                    <div className="stock-row">
                      <span>Capacity</span>
                      <strong>
                        {Number(warehouse.capacity).toLocaleString("en-IN")}
                      </strong>
                    </div>

                    <div className="stock-row">
                      <span>Batches held</span>
                      <strong>{warehouse.batches_held}</strong>
                    </div>

                    <div className="utilisation-heading">
                      <span>Utilisation</span>
                      <strong>{warehouse.utilisation_pct}%</strong>
                    </div>

                    <div
                      className="progress-track"
                      role="progressbar"
                      aria-label={`${warehouse.name} utilisation`}
                      aria-valuenow={percentage}
                      aria-valuemin={0}
                      aria-valuemax={100}
                    >
                      <div
                        className="progress-fill"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </article>
                );
              })}
            </div>
          </section>
        </>
      )}

      <footer className="dashboard-footer">
        Supply Chain Traceability System · Live PostgreSQL data
      </footer>
    </main>
  );
}