import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export function GET() {
  const url = process.env["DOWNLOAD_URL"];
  if (url) return NextResponse.redirect(url, 302);
  const html = `<!doctype html><html><body style="background:#0c0c0a;color:#f4f1ea;font-family:sans-serif;padding:48px"><h1>Download not linked yet</h1><p>Set DOWNLOAD_URL on the Vercel project to the notarized Stage disk image, then redeploy.</p><p><a style="color:#e8a04a" href="/">Back to Stage</a></p></body></html>`;
  return new NextResponse(html, { status: 200, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } });
}
