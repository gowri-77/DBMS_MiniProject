"use client";

import { useEffect, useState } from "react";

type Order = {
  order_id: number;
  order_date: string;
  order_status: string;
  retailer: string;
  city: string;
  batches_ordered: number | string;
  total_quantity: number;
  shipment_status: string | null;
  delivered_at: string | null;
};

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    fetch("/api/orders")
      .then((response) => {
        if (!response.ok) {
          throw new Error("Failed to load orders");
        }
        return response.json();
      })
      .then((data: Order[]) => setOrders(data))
      .catch(() => setError("Could not load orders. Please try again."))
      .finally(() => setLoading(false));
  }, []);

  const formatDate = (date: string | null) => {
    if (!date) return "—";

    return new Date(date).toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      timeZone: "UTC",
    });
  };

  const statusClass = (status: string | null) => {
    if (!status) return "status-pending";

    switch (status.toUpperCase()) {
      case "DELIVERED":
        return "status-delivered";
      case "SHIPPED":
      case "IN_TRANSIT":
        return "status-shipped";
      case "CONFIRMED":
        return "status-confirmed";
      default:
        return "status-pending";
    }
  };

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SUPPLY CHAIN TRACEABILITY</p>
          <h1>Order Management</h1>
          <p className="subtitle">
            Track retailer orders and shipment progress.
          </p>
        </div>

        <a className="back-link" href="/">
          ← Dashboard
        </a>
      </header>

      <section className="dashboard-section">
        <h2>Orders</h2>

        {loading && <p>Loading orders...</p>}

        {error && <p role="alert">{error}</p>}

        {!loading && !error && (
          <>
            <p className="subtitle">
              {orders.length} orders found
            </p>

            <div className="table-container">
              <table className="inventory-table">
                <thead>
                  <tr>
                    <th>Order ID</th>
                    <th>Order Date</th>
                    <th>Retailer</th>
                    <th>City</th>
                    <th>Quantity</th>
                    <th>Order Status</th>
                    <th>Shipment</th>
                    <th>Delivered At</th>
                  </tr>
                </thead>

                <tbody>
                  {orders.map((order) => (
                    <tr key={order.order_id}>
                      <td>#{order.order_id}</td>
                      <td>{formatDate(order.order_date)}</td>
                      <td>{order.retailer}</td>
                      <td>{order.city}</td>
                      <td>
                        {Number(order.total_quantity).toLocaleString("en-IN")}
                      </td>
                      <td>
                        <span
                          className={`batch-status ${statusClass(order.order_status)}`}
                        >
                          {order.order_status}
                        </span>
                      </td>
                      <td>
                        <span
                          className={`batch-status ${statusClass(order.shipment_status)}`}
                        >
                          {order.shipment_status ?? "Not shipped"}
                        </span>
                      </td>
                      <td>{formatDate(order.delivered_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </section>
    </main>
  );
}