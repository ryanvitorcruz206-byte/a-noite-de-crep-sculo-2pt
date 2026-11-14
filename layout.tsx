import "./globals.css";
import type { Metadata } from "next";
export const metadata: Metadata = { title: "Noite de Crepúsculo | RPG", description: "Um refúgio online para campanhas e histórias extraordinárias." };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="pt-BR"><body>{children}</body></html>; }
