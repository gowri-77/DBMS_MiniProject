"use client";

import { useEffect, useState } from "react";

type Inspection = {
  inspection_id: number;
  batch_id: number;
  batch_code: string;
  inspector_id: number;
  inspected_at: string;
  result: "PASS" | "FAIL" | "CONDITIONAL";
  score: number | null;
  defect_type: string | null;
  notes: string | null;
};

export default function InspectionsPage() {
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("/api/inspections")
      .then(async (res) => {
        if (!res.ok) {
          throw new Error("Failed to load inspections");
        }

        return res.json();
      })
      .then((data) => {
        setInspections(data);
        setLoading(false);
      })
      .catch(() => {
        setError("Unable to load inspection data.");
        setLoading(false);
      });
  }, []);

  const total = inspections.length;
  const passed = inspections.filter((i) => i.result === "PASS").length;
  const failed = inspections.filter((i) => i.result === "FAIL").length;
  const conditional = inspections.filter(
    (i) => i.result === "CONDITIONAL"
  ).length;

  const getBadgeStyle = (result: string) => {
    if (result === "PASS") {
      return {
        backgroundColor: "#dcfce7",
        color: "#15803d",
      };
    }

    if (result === "FAIL") {
      return {
        backgroundColor: "#fee2e2",
        color: "#dc2626",
      };
    }

    return {
      backgroundColor: "#fef3c7",
      color: "#b45309",
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
            Inspections
          </h1>

          <p
            style={{
              color: "#64748b",
              fontSize: "17px",
              marginTop: "12px",
            }}
          >
            Monitor quality inspections across all product batches.
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
        <SummaryCard title="Total Inspections" value={total} />
        <SummaryCard title="Passed" value={passed} color="#16a34a" />
        <SummaryCard title="Failed" value={failed} color="#dc2626" />
        <SummaryCard
          title="Conditional"
          value={conditional}
          color="#d97706"
        />
      </div>

      {/* Inspection Records */}
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
            Inspection Records
          </h2>

          <p style={{ color: "#64748b", marginBottom: 0 }}>
            Latest quality inspection activity.
          </p>
        </div>

        {loading ? (
          <p style={{ color: "#64748b" }}>Loading inspection records...</p>
        ) : error ? (
          <p style={{ color: "#dc2626" }}>{error}</p>
        ) : inspections.length === 0 ? (
          <div
            style={{
              textAlign: "center",
              padding: "60px 20px",
              color: "#64748b",
            }}
          >
            <div style={{ fontSize: "42px", marginBottom: "15px" }}>📋</div>

            <h3 style={{ color: "#334155" }}>No inspections found</h3>

            <p>
              Inspection records will appear here once batches are inspected.
            </p>
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table
              style={{
                width: "100%",
                borderCollapse: "collapse",
                minWidth: "900px",
              }}
            >
              <thead>
                <tr style={{ backgroundColor: "#f8fafc" }}>
                  <TableHeader>Batch</TableHeader>
                  <TableHeader>Inspector</TableHeader>
                  <TableHeader>Date</TableHeader>
                  <TableHeader>Result</TableHeader>
                  <TableHeader>Score</TableHeader>
                  <TableHeader>Defect Type</TableHeader>
                  <TableHeader>Notes</TableHeader>
                </tr>
              </thead>

              <tbody>
                {inspections.map((inspection) => (
                  <tr
                    key={inspection.inspection_id}
                    style={{
                      borderBottom: "1px solid #e5e7eb",
                    }}
                  >
                    <TableCell>
                      <strong>{inspection.batch_code}</strong>
                    </TableCell>

                    <TableCell>
                      Inspector #{inspection.inspector_id}
                    </TableCell>

                    <TableCell>
                      {new Date(
                        inspection.inspected_at
                      ).toLocaleDateString()}
                    </TableCell>

                    <TableCell>
                      <span
                        style={{
                          ...getBadgeStyle(inspection.result),
                          padding: "7px 12px",
                          borderRadius: "20px",
                          fontSize: "12px",
                          fontWeight: 700,
                        }}
                      >
                        {inspection.result}
                      </span>
                    </TableCell>

                    <TableCell>
                      {inspection.score ?? "—"}
                    </TableCell>

                    <TableCell>
                      {inspection.defect_type ?? "None"}
                    </TableCell>

                    <TableCell>
                      {inspection.notes ?? "—"}
                    </TableCell>
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
