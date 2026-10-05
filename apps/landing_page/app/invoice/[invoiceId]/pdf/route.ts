
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ invoiceId: string }> }
) {
  const { invoiceId } = await params;

  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([595.28, 841.89]);

  const regular = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const { width, height } = page.getSize();

  const navy = rgb(0.07, 0.09, 0.14);
  const gray = rgb(0.42, 0.45, 0.50);
  const light = rgb(0.95, 0.96, 0.97);
  const white = rgb(1, 1, 1);

  page.drawRectangle({
    x: 0,
    y: height - 105,
    width,
    height: 105,
    color: navy,
  });

  page.drawText("NUSA-DHIPA", {
    x: 42,
    y: height - 48,
    size: 23,
    font: bold,
    color: white,
  });

  page.drawText("BUSINESS OS", {
    x: 43,
    y: height - 69,
    size: 9,
    font: regular,
    color: rgb(0.8, 0.82, 0.86),
  });

  page.drawText("INVOICE", {
    x: 42,
    y: height - 145,
    size: 10,
    font: bold,
    color: gray,
  });

  page.drawText(invoiceId, {
    x: 42,
    y: height - 177,
    size: 25,
    font: bold,
    color: navy,
  });

  page.drawText("Order ID", {
    x: 410,
    y: height - 145,
    size: 9,
    font: bold,
    color: gray,
  });

  page.drawText("ND-LEGAL-000123", {
    x: 410,
    y: height - 163,
    size: 10,
    font: bold,
    color: navy,
  });

  page.drawRectangle({
    x: 42,
    y: height - 260,
    width: width - 84,
    height: 65,
    color: light,
  });

  page.drawText("CUSTOMER", {
    x: 57,
    y: height - 215,
    size: 8,
    font: bold,
    color: gray,
  });

  page.drawText("PT Digi Media Komunika", {
    x: 57,
    y: height - 233,
    size: 11,
    font: bold,
    color: navy,
  });

  page.drawText("ptdigimedia@gmail.com", {
    x: 57,
    y: height - 248,
    size: 8,
    font: regular,
    color: gray,
  });

  page.drawText("BUSINESS", {
    x: 330,
    y: height - 215,
    size: 8,
    font: bold,
    color: gray,
  });

  page.drawText("PT Digi Media Komunika", {
    x: 330,
    y: height - 233,
    size: 11,
    font: bold,
    color: navy,
  });

  page.drawText("LEGAL PACKAGE", {
    x: 42,
    y: height - 300,
    size: 8,
    font: bold,
    color: gray,
  });

  page.drawText("PT Perorangan", {
    x: 42,
    y: height - 319,
    size: 12,
    font: bold,
    color: navy,
  });

  page.drawText("KBLI", {
    x: 270,
    y: height - 300,
    size: 8,
    font: bold,
    color: gray,
  });

  page.drawText("56101", {
    x: 270,
    y: height - 319,
    size: 12,
    font: bold,
    color: navy,
  });

  page.drawText("BIDANG USAHA", {
    x: 390,
    y: height - 300,
    size: 8,
    font: bold,
    color: gray,
  });

  page.drawText("Restoran", {
    x: 390,
    y: height - 319,
    size: 12,
    font: bold,
    color: navy,
  });

  const top = height - 365;

  page.drawLine({
    start: { x: 42, y: top },
    end: { x: width - 42, y: top },
    thickness: 1,
    color: light,
  });

  page.drawText("PAYMENT SUMMARY", {
    x: 42,
    y: top - 25,
    size: 9,
    font: bold,
    color: gray,
  });

  page.drawText("Total Invoice", {
    x: 42,
    y: top - 55,
    size: 11,
    font: regular,
    color: gray,
  });

  page.drawText("Rp 1.500.000", {
    x: 405,
    y: top - 55,
    size: 14,
    font: bold,
    color: navy,
  });

  page.drawText("DP 60%", {
    x: 42,
    y: top - 83,
    size: 11,
    font: regular,
    color: gray,
  });

  page.drawText("Rp 900.000", {
    x: 420,
    y: top - 83,
    size: 11,
    font: bold,
    color: navy,
  });

  page.drawText("Sisa 40%", {
    x: 42,
    y: top - 111,
    size: 11,
    font: regular,
    color: gray,
  });

  page.drawText("Rp 600.000", {
    x: 420,
    y: top - 111,
    size: 11,
    font: bold,
    color: navy,
  });

  page.drawRectangle({
    x: 42,
    y: top - 160,
    width: width - 84,
    height: 30,
    color: rgb(1, 0.96, 0.91),
  });

  page.drawText("DP_PENDING", {
    x: width / 2 - 40,
    y: top - 149,
    size: 10,
    font: bold,
    color: rgb(0.75, 0.35, 0.05),
  });

  page.drawLine({
    start: { x: 42, y: 75 },
    end: { x: width - 42, y: 75 },
    thickness: 1,
    color: light,
  });

  page.drawText(
    "NUSA-DHIPA Business OS - Invoice Document",
    {
      x: 42,
      y: 52,
      size: 8,
      font: regular,
      color: gray,
    }
  );

  const pdfBytes = await pdfDoc.save();

  // pdf-lib returns Uint8Array<ArrayBufferLike>.
  // Convert it to a Node.js Buffer so it satisfies Response BodyInit.
  const pdfBuffer = Buffer.from(pdfBytes);

  return new Response(pdfBuffer, {
    status: 200,
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${invoiceId}.pdf"`,
      "Cache-Control": "no-store",
    },
  });
}
