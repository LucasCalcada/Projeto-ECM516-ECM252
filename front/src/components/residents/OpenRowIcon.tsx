import { ChevronDown, ChevronRight } from 'lucide-react';

export default function OpenRowIcon(props: { opened: boolean }) {
  return props.opened ? <ChevronDown /> : <ChevronRight />;
}
