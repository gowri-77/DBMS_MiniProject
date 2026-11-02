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
        COUNT(rb.batch_id) AS affected_batch_count,
        COALESCE(SUM(rb.units_affected), 0) AS total_units_affected
      FROM recalls r
      LEFT JOIN recall_batches rb
        ON r.recall_id = rb.recall_id
      GROUP BY
        r.recall_id,
        r.recall_code,
        r.source_inspection_id,
        r.initiated_by,
        r.reason,
        r.severity,
        r.status,
        r.initiated_at,
        r.closed_at
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

// CREATE a recall
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const {
      recall_code,
      initiated_by,
      reason,
      severity,
      batch_ids,
    } = body;

    if (
      !recall_code ||
      !initiated_by ||
      !reason ||
      !severity ||
      !Array.isArray(batch_ids) ||
      batch_ids.length === 0
    ) {
      return NextResponse.json(
        {
          error:
            "recall_code, initiated_by, reason, severity and at least one batch are required",
        },
        { status: 400 }
      );
    }

    // Create the recall
    const recallResult = await pool.query(
      `
      INSERT INTO recalls (
        recall_code,
        initiated_by,
        reason,
        severity
      )
      VALUES ($1, $2, $3, $4)
      RETURNING *
      `,
      [recall_code, initiated_by, reason, severity]
    );

    const recall = recallResult.rows[0];

    // Add every affected batch and mark it as recalled
    for (const batch of batch_ids) {
      const { batch_id, units_affected } = batch;

      await pool.query(
        `
        INSERT INTO recall_batches (
          recall_id,
          batch_id,
          units_affected
        )
        VALUES ($1, $2, $3)
        `,
        [recall.recall_id, batch_id, units_affected]
      );

      await pool.query(
        `
        UPDATE batches
        SET status = 'RECALLED'
        WHERE batch_id = $1
        `,
        [batch_id]
      );
    }

    return NextResponse.json(recall, { status: 201 });
  } catch (error) {
    console.error("Failed to create recall:", error);

    return NextResponse.json(
      { error: "Failed to create recall" },
      { status: 500 }
    );
  }
}