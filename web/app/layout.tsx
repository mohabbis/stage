import type { Metadata } from "next";
import { Instrument_Serif, Outfit } from "next/font/google";
import "./globals.css";

const serif = Instrument_Serif({ subsets: ["latin"], weight: "400", variable: "--font-serif" });
const sans = Outfit({ subsets: ["latin"], variable: "--font-sans" });

export const metadata: Metadata = {
  title: "Stage — Put the desk back",
  description:
    "Stage saves the arrangement of a Mac workspace and restores it later. Windows, displays, tabs, folders, and terminals. Local, native, and honest about what macOS will allow.",
};

export const viewport = { themeColor: "#0e0d0b" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`${serif.variable} ${sans.variable}`}>{children}</body>
    </html>
  );
}
