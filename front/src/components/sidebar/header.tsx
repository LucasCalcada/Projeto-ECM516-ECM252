import { Building } from 'lucide-react';

export default function BuldingInfo() {
  return (
    <div className="mb-8 flex items-center gap-2">
      <div className="rounded-full bg-neutral-800 p-2">
        <Building size="24" />
      </div>
      <p className="font-bold">Building</p>
    </div>
  );
}
