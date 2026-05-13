import { ShieldCheck } from 'lucide-react';

interface VisitorAccessHeaderProps {
  outletName: string;
}

export default function VisitorAccessHeader({ outletName }: VisitorAccessHeaderProps) {
  return (
    <header className="mb-6 flex items-center gap-2 text-cyan-300">
      <ShieldCheck size={22} />
      <h1 className="text-2xl font-bold text-neutral-100">{outletName}</h1>
    </header>
  );
}
