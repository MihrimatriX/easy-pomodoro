import type { Metadata, Viewport } from "next";
import { JetBrains_Mono, Plus_Jakarta_Sans } from "next/font/google";
import { APP_HIGHLIGHTS, APP_NAME } from "@shared/app-copy";
import { getSiteUrl, SEO } from "@/lib/seo";
import { Providers } from "@/components/Providers";
import { RegisterSW } from "@/components/RegisterSW";
import "./globals.css";
import "./ui-styles.css";

const plusJakarta = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin", "latin-ext"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  display: "swap",
});

const siteUrl = getSiteUrl();
const googleVerify = process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION;

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: SEO.title,
    template: `%s · ${SEO.name}`,
  },
  description: SEO.description,
  applicationName: SEO.name,
  keywords: [...SEO.keywords],
  authors: [{ name: SEO.name, url: siteUrl }],
  creator: SEO.name,
  publisher: SEO.name,
  category: "productivity",
  referrer: "origin-when-cross-origin",
  formatDetection: { email: false, address: false, telephone: false },
  alternates: {
    canonical: "/",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  icons: {
    icon: [
      { url: "/favicon.ico" },
      { url: "/icons/icon.svg", type: "image/svg+xml" },
    ],
    apple: [{ url: "/apple-icon", sizes: "180x180", type: "image/png" }],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: SEO.shortName,
  },
  manifest: "/manifest.webmanifest",
  openGraph: {
    type: "website",
    url: "/",
    siteName: SEO.name,
    title: SEO.title,
    description: SEO.description,
    locale: SEO.locale,
    alternateLocale: ["en_US"],
  },
  twitter: {
    card: "summary_large_image",
    title: SEO.title,
    description: SEO.description,
  },
  ...(googleVerify ? { verification: { google: googleVerify } } : {}),
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#e8eef8" },
    { media: "(prefers-color-scheme: dark)", color: "#10141f" },
  ],
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "WebApplication",
  name: APP_NAME,
  alternateName: SEO.shortName,
  url: siteUrl,
  image: `${siteUrl}/opengraph-image`,
  screenshot: `${siteUrl}/opengraph-image`,
  description: SEO.description,
  applicationCategory: "ProductivityApplication",
  operatingSystem: "Web",
  browserRequirements: "Requires JavaScript",
  inLanguage: ["tr", "en"],
  isAccessibleForFree: true,
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  featureList: APP_HIGHLIGHTS.map((h) => h.label),
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" suppressHydrationWarning>
      <body
        className={`${plusJakarta.variable} ${jetbrainsMono.variable} min-h-dvh antialiased`}
      >
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c"),
          }}
        />
        <Providers>
          <RegisterSW />
          {children}
        </Providers>
      </body>
    </html>
  );
}
