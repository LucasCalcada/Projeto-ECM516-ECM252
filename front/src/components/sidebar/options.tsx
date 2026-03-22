import { LogOut, Settings } from "lucide-react";

export default function Options() {
  return (
    <div className="flex flex-col gap-2 p-1 px-3 pt-4 border-t-1 border-neutral-800">
      <div className="flex gap-2 items-center">
        <Settings size="16" />
        <p>Options</p>
      </div>
      <div className="flex gap-2 items-center">
        <LogOut size="16" />
        <p>Sign Out</p>
      </div>
    </div>
  );
}
