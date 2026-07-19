import Nav from '@/components/nav';
import Footer from '@/components/footer';

export default function PortalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Nav />
      <main className="relative min-h-[70vh]">{children}</main>
      <Footer />
    </>
  );
}
