interface ButtonProps {
  text: string;
}

export default function Button({ text }: ButtonProps) {
  return (
    <button
      type="submit"
      className="mt-4 p-3 w-full bg-blue-600 text-white font-bold rounded-md hover:bg-blue-700 transition-colors"
    >
      {text}
    </button>
  );
}
