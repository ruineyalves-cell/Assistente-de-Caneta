import Nav from '@/components/nav';
import Footer from '@/components/footer';
import { PortalAuthProvider } from './_lib/auth-provider';

export default function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <PortalAuthProvider>
      <Nav />
      <main className="relative min-h-[70vh]">{children}</main>
      <Footer />
    </PortalAuthProvider>
  );
}
