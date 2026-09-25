import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export function GET() {
  const url = process.env["DOWNLOAD_URL"];
  return NextResponse.json({ available: Boolean(url) }, { headers: { "cache-control": "no-store" } });
}
