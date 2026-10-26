"use client";

import { useEffect, useState } from "react";

type Batch = {
  batch_id: number;
  batch_code: string;
  product: string;
  expiry_date: string;
  days_left: number;
  units_in_stock: string;
};

export default function BatchesPage() {
  const [batches, setBatches] = useState<Batch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadBatches() {
      try {
        const response = await fetch("/api/batches");

        if (!response.ok) {
          throw new Error("Unable to load batches");
        }

        const data: Batch[] = await response.json();
        setBatches(data);
      } catch {
        setError("Could not load batches. Please try again.");
      } finally {
        setLoading(false);
      }
    }

    loadBatches();
  }, []);

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SUPPLY CHAIN MANAGEMENT</p>
          <h1>Batch Management</h1>
          <p className="subtitle">
            Monitor product batches and their upcoming expiry dates.
          </p>
        </div>

        <a className="back-link" href="/">
          ← Inventory Dashboard
        </a>
      </header>

      <section className="warehouse-section">
        <div className="section-heading">
          <div>
            <h2>Expiring Batches</h2>
            <p>Batches returned by the database expiry view</p>
          </div>

          <span className="record-count">
            {batches.length} batches
          </span>
        </div>

        {loading && <p className="message">Loading batches...</p>}

        {error && <p className="error-message">{error}</p>}

        {!loading && !error && batches.length === 0 && (
          <p className="message">No batches found in the expiry view.</p>
        )}

        {!loading && !error && batches.length > 0 && (
          <div className="warehouse-grid">
            {batches.map((batch) => (
              <article className="warehouse-card" key={batch.batch_id}>
                <div className="warehouse-top">
                  <div>
                    <p className="location">Batch: {batch.batch_code}</p>
                    <h3>{batch.product}</h3>
                  </div>

                  <span className="warehouse-icon">BT</span>
                </div>

                <div className="stock-row">
                  <span>Units in stock</span>
                  <strong>
                    {Number(batch.units_in_stock).toLocaleString("en-IN")}
                  </strong>
                </div>

                <div className="stock-row">
                  <span>Expiry date</span>
                  <strong>
                    {new Date(batch.expiry_date).toLocaleDateString("en-IN", {
                      day: "2-digit",
                      month: "short",
                      year: "numeric",
                      timeZone: "UTC",
                    })}
                  </strong>
                </div>

                <div className="stock-row">
                  <span>Days until expiry</span>
                  <strong>{batch.days_left} days</strong>
                </div>

                <div className="batch-status">
                  {batch.days_left <= 30
                    ? "Expiring soon"
                    : batch.days_left <= 90
                      ? "Expiry approaching"
                      : "Expiry on record"}
                </div>
              </article>
            ))}
          </div>
        )}
      </section>

      <footer className="dashboard-footer">
        Supply Chain Traceability System · Live PostgreSQL data
      </footer>
    </main>
  );
}