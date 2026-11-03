import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";

// GET all recalls
export async function GET() {
  try {
    const result = await pool.query(`
      SELECT
        r.recall_id,
        r.recall_code,
        r.source_inspection_id,
        r.initiated_by,
        r.reason,
        r.severity,
        r.status,
        r.initiated_at,
        r.closed_at,
        COUNT(rb.batch_id)::INT AS affected_batch_count,
        COALESCE(SUM(rb.units_affected), 0)::INT
          AS total_units_affected
      FROM recalls r
      LEFT JOIN recall_batches rb
        ON r.recall_id = rb.recall_id
      GROUP BY r.recall_id
      ORDER BY r.initiated_at DESC
    `);

    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Recall query failed:", error);

    return NextResponse.json(
      { error: "Failed to load recalls" },
      { status: 500 }
    );
  }
}

// CREATE a recall using the PostgreSQL procedure
export async function POST(request: NextRequest) {
  const client = await pool.connect();

  try {
    const body = await request.json();

    const {
      recall_code,
      source_inspection_id,
      initiated_by,
      reason,
      severity,
      batch_ids,
    } = body;

    if (
      typeof recall_code !== "string" ||
      !recall_code.trim() ||
      recall_code.length > 30 ||
      !Number.isInteger(Number(initiated_by)) ||
      Number(initiated_by) <= 0 ||
      typeof reason !== "string" ||
      !reason.trim() ||
      !["LOW", "MEDIUM", "HIGH", "CRITICAL"].includes(severity) ||
      !Array.isArray(batch_ids) ||
      batch_ids.length === 0
    ) {
      return NextResponse.json(
        { error: "Invalid or missing recall details" },
        { status: 400 }
      );
    }

    const inspectionId =
      source_inspection_id == null
        ? null
        : Number(source_inspection_id);

    if (
      inspectionId !== null &&
      (!Number.isInteger(inspectionId) || inspectionId <= 0)
    ) {
      return NextResponse.json(
        { error: "Invalid source inspection ID" },
        { status: 400 }
      );
    }

    // Support both [1, 2] and [{ batch_id: 1 }, { batch_id: 2 }]
    const batchIds = batch_ids.map((batch: number | { batch_id: number }) =>
      typeof batch === "number" ? batch : Number(batch.batch_id)
    );

    if (
      batchIds.some(
        (id: number) => !Number.isInteger(id) || id <= 0
      )
    ) {
      return NextResponse.json(
        { error: "Invalid batch IDs" },
        { status: 400 }
      );
    }

    await client.query("BEGIN");

    // Call the existing PostgreSQL procedure
    await client.query(
      `
      CALL initiate_recall(
        $1::VARCHAR(30),
        $2::INT,
        $3::INT,
        $4::TEXT,
        $5::VARCHAR(10),
        $6::INT[]
      )
      `,
      [
        recall_code.trim(),
        inspectionId,
        Number(initiated_by),
        reason.trim(),
        severity,
        batchIds,
      ]
    );

    // Retrieve the newly created recall
    const result = await client.query(
      `
      SELECT
        r.recall_id,
        r.recall_code,
        r.source_inspection_id,
        r.initiated_by,
        r.reason,
        r.severity,
        r.status,
        r.initiated_at,
        r.closed_at,
        COUNT(rb.batch_id)::INT AS affected_batch_count,
        COALESCE(SUM(rb.units_affected), 0)::INT
          AS total_units_affected
      FROM recalls r
      LEFT JOIN recall_batches rb
        ON r.recall_id = rb.recall_id
      WHERE r.recall_code = $1
      GROUP BY r.recall_id
      `,
      [recall_code.trim()]
    );

    await client.query("COMMIT");

    return NextResponse.json(result.rows[0], { status: 201 });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Failed to create recall:", error);

    return NextResponse.json(
      { error: "Failed to create recall" },
      { status: 500 }
    );
  } finally {
    client.release();
  }
}