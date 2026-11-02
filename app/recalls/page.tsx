"use client";

import { useEffect, useState } from "react";

type Recall = {
  recall_id: number;
  recall_code: string;
  source_inspection_id: number | null;
  initiated_by: number;
  reason: string;
  severity: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
  status: "OPEN" | "IN_PROGRESS" | "CLOSED";
  initiated_at: string;
  closed_at: string | null;
  affected_batch_count: number | string;
  total_units_affected: number | string;
};

export default function RecallsPage() {
  const [recalls, setRecalls] = useState<Recall[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("/api/recalls")
      .then(async (res) => {
        if (!res.ok) {
          throw new Error("Failed to load recalls");
        }

        return res.json();
      })
      .then((data) => {
        setRecalls(data);
        setLoading(false);
      })
      .catch(() => {
        setError("Unable to load recall data.");
        setLoading(false);
      });
  }, []);

  const total = recalls.length;
  const open = recalls.filter((r) => r.status === "OPEN").length;
  const inProgress = recalls.filter(
    (r) => r.status === "IN_PROGRESS"
  ).length;
  const closed = recalls.filter((r) => r.status === "CLOSED").length;

  const getStatusStyle = (status: string) => {
    if (status === "OPEN") {
      return {
        backgroundColor: "#fee2e2",
        color: "#dc2626",
      };
    }

    if (status === "IN_PROGRESS") {
      return {
        backgroundColor: "#fef3c7",
        color: "#b45309",
      };
    }

    return {
      backgroundColor: "#dcfce7",
      color: "#15803d",
    };
  };

  const getSeverityStyle = (severity: string) => {
    if (severity === "CRITICAL") {
      return {
        backgroundColor: "#7f1d1d",
        color: "#ffffff",
      };
    }

    if (severity === "HIGH") {
      return {
        backgroundColor: "#fee2e2",
        color: "#dc2626",
      };
    }

    if (severity === "MEDIUM") {
      return {
        backgroundColor: "#fef3c7",
        color: "#b45309",
      };
    }

    return {
      backgroundColor: "#dbeafe",
      color: "#2563eb",
    };
  };

  return (
    <main
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f7fb",
        padding: "40px 7%",
        fontFamily: "Arial, sans-serif",
        color: "#14213d",
      }}
    >
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "40px",
        }}
      >
        <div>
          <p
            style={{
              color: "#2563eb",
              fontSize: "13px",
              fontWeight: "bold",
              letterSpacing: "2px",
              marginBottom: "10px",
            }}
          >
            SUPPLY CHAIN MANAGEMENT
          </p>

          <h1
            style={{
              fontSize: "42px",
              margin: 0,
              fontWeight: 500,
            }}
          >
            Product Recalls
          </h1>

          <p
            style={{
              color: "#64748b",
              fontSize: "17px",
              marginTop: "12px",
            }}
          >
            Monitor and manage product recalls across the supply chain.
          </p>
        </div>

        <a
          href="/"
          style={{
            textDecoration: "none",
            backgroundColor: "white",
            border: "1px solid #dbe3ef",
            padding: "13px 20px",
            borderRadius: "12px",
            color: "#2563eb",
            fontWeight: 600,
          }}
        >
          ← Dashboard
        </a>
      </div>

      {/* Summary Cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: "20px",
          marginBottom: "35px",
        }}
      >
        <SummaryCard title="Total Recalls" value={total} />
        <SummaryCard title="Open" value={open} color="#dc2626" />
        <SummaryCard
          title="In Progress"
          value={inProgress}
          color="#d97706"
        />
        <SummaryCard title="Closed" value={closed} color="#16a34a" />
      </div>

      {/* Recall Records */}
      <section
        style={{
          backgroundColor: "white",
          borderRadius: "18px",
          padding: "28px",
          boxShadow: "0 4px 20px rgba(0,0,0,0.05)",
          border: "1px solid #e5e7eb",
        }}
      >
        <div style={{ marginBottom: "25px" }}>
          <h2 style={{ margin: 0, fontSize: "24px", fontWeight: 600 }}>
            Recall Records
          </h2>

          <p style={{ color: "#64748b", marginBottom: 0 }}>
            Track active and completed product recall activity.
          </p>
        </div>

        {loading ? (
          <p style={{ color: "#64748b" }}>Loading recall records...</p>
        ) : error ? (
          <p style={{ color: "#dc2626" }}>{error}</p>
        ) : recalls.length === 0 ? (
          <div
            style={{
              textAlign: "center",
              padding: "60px 20px",
              color: "#64748b",
            }}
          >
            <div style={{ fontSize: "42px", marginBottom: "15px" }}>
              ⚠️
            </div>

            <h3 style={{ color: "#334155" }}>No recalls found</h3>

            <p>
              Product recall records will appear here when recalls are
              initiated.
            </p>
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table
              style={{
                width: "100%",
                borderCollapse: "collapse",
                minWidth: "1100px",
              }}
            >
              <thead>
                <tr style={{ backgroundColor: "#f8fafc" }}>
                  <TableHeader>Recall Code</TableHeader>
                  <TableHeader>Severity</TableHeader>
                  <TableHeader>Status</TableHeader>
                  <TableHeader>Affected Batches</TableHeader>
                  <TableHeader>Units Affected</TableHeader>
                  <TableHeader>Initiated</TableHeader>
                  <TableHeader>Reason</TableHeader>
                </tr>
              </thead>

              <tbody>
                {recalls.map((recall) => (
                  <tr
                    key={recall.recall_id}
                    style={{
                      borderBottom: "1px solid #e5e7eb",
                    }}
                  >
                    <TableCell>
                      <strong>{recall.recall_code}</strong>
                    </TableCell>

                    <TableCell>
                      <span
                        style={{
                          ...getSeverityStyle(recall.severity),
                          padding: "7px 12px",
                          borderRadius: "20px",
                          fontSize: "12px",
                          fontWeight: 700,
                        }}
                      >
                        {recall.severity}
                      </span>
                    </TableCell>

                    <TableCell>
                      <span
                        style={{
                          ...getStatusStyle(recall.status),
                          padding: "7px 12px",
                          borderRadius: "20px",
                          fontSize: "12px",
                          fontWeight: 700,
                        }}
                      >
                        {recall.status.replace("_", " ")}
                      </span>
                    </TableCell>

                    <TableCell>
                      {recall.affected_batch_count}
                    </TableCell>

                    <TableCell>
                      {Number(
                        recall.total_units_affected
                      ).toLocaleString()}
                    </TableCell>

                    <TableCell>
                      {new Date(
                        recall.initiated_at
                      ).toLocaleDateString()}
                    </TableCell>

                    <TableCell>{recall.reason}</TableCell>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
}

function SummaryCard({
  title,
  value,
  color = "#14213d",
}: {
  title: string;
  value: number;
  color?: string;
}) {
  return (
    <div
      style={{
        backgroundColor: "white",
        borderRadius: "16px",
        padding: "24px",
        border: "1px solid #e5e7eb",
        boxShadow: "0 4px 15px rgba(0,0,0,0.04)",
      }}
    >
      <p
        style={{
          margin: 0,
          color: "#64748b",
          fontSize: "15px",
        }}
      >
        {title}
      </p>

      <h2
        style={{
          margin: "15px 0 0",
          fontSize: "34px",
          color,
        }}
      >
        {value}
      </h2>
    </div>
  );
}

function TableHeader({ children }: { children: React.ReactNode }) {
  return (
    <th
      style={{
        textAlign: "left",
        padding: "15px",
        color: "#64748b",
        fontSize: "13px",
      }}
    >
      {children}
    </th>
  );
}

function TableCell({ children }: { children: React.ReactNode }) {
  return (
    <td
      style={{
        padding: "17px 15px",
        fontSize: "14px",
        color: "#334155",
      }}
    >
      {children}
    </td>
  );
}
