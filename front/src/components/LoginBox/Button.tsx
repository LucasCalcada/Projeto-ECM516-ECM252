interface ButtonProps {
  text: string;
  type: string;
  onClick?: () => void;
}

export default function Button({ text }: ButtonProps) {
  return (
    <button className="mt-4 w-full rounded-md bg-blue-600 p-3 font-bold text-white transition-colors hover:bg-blue-700">
      {text}
    </button>
  );
}
