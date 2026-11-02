import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";

// GET all inspections
export async function GET() {
  try {
    const result = await pool.query(`
      SELECT
        i.inspection_id,
        i.batch_id,
        b.batch_code,
        i.inspector_id,
        i.inspected_at,
        i.result,
        i.score,
        i.defect_type,
        i.notes
      FROM inspections i
      JOIN batches b ON i.batch_id = b.batch_id
      ORDER BY i.inspected_at DESC
    `);

    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Inspection query failed:", error);

    return NextResponse.json(
      { error: "Failed to load inspections" },
      { status: 500 }
    );
  }
}

// CREATE a new inspection
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const {
      batch_id,
      inspector_id,
      result,
      score,
      defect_type,
      notes,
    } = body;

    if (!batch_id || !inspector_id || !result) {
      return NextResponse.json(
        {
          error: "batch_id, inspector_id and result are required",
        },
        { status: 400 }
      );
    }

    if (result === "FAIL" && !defect_type) {
      return NextResponse.json(
        {
          error: "defect_type is required for a failed inspection",
        },
        { status: 400 }
      );
    }

    const query = `
      INSERT INTO inspections (
        batch_id,
        inspector_id,
        result,
        score,
        defect_type,
        notes
      )
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;

    const values = [
      batch_id,
      inspector_id,
      result,
      score || null,
      defect_type || null,
      notes || null,
    ];

    const resultQuery = await pool.query(query, values);

    return NextResponse.json(resultQuery.rows[0], {
      status: 201,
    });
  } catch (error) {
    console.error("Failed to create inspection:", error);

    return NextResponse.json(
      { error: "Failed to create inspection" },
      { status: 500 }
    );
  }
}