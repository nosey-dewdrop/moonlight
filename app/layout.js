import { Press_Start_2P, VT323 } from "next/font/google";
import "./globals.css";

const pressStart = Press_Start_2P({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-pixel",
});

const vt323 = VT323({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-vt323",
});

export const metadata = {
  title: "Moonlight",
  description: "Ay takvimleri, astroloji ve gökyüzü",
};

export default function RootLayout({ children }) {
  return (
    <html lang="tr">
      <body className={`${pressStart.variable} ${vt323.variable}`}>
        {children}
      </body>
    </html>
  );
}
