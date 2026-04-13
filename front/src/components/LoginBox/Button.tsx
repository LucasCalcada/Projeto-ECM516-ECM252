interface ButtonProps {
  text: string;
  type: string;
  onClick?: () => void;
}

export default function Button({ text }: ButtonProps) {
  return (
    <button className="mt-4 p-3 w-full bg-blue-600 text-white font-bold rounded-md hover:bg-blue-700 transition-colors">
      {text}
    </button>
  );
}
