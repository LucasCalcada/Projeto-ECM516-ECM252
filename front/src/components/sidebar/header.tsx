import { Building } from "lucide-react";

export default function BuldingInfo() {
  return (
    <div className="flex gap-2 items-center mb-8">
      <div className="p-2 rounded-full bg-neutral-800">
        <Building size="24" />
      </div>
      <p className="font-bold">Building</p>
    </div>
  );
}
