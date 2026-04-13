interface TextFieldProps {
  id: string;
  label: string;
  type: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void; // A função que atualiza o estado
  placeholder: string;
}

export default function TextField({
  id,
  label,
  type,
  value,
  onChange,
  placeholder,
}: TextFieldProps) {
  return (
    <div className="flex flex-col">
      <label htmlFor={id} className="mb-2 font-bold text-neutral-100">
        {label}
      </label>
      <input
        type={type}
        id={id}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required
        className="rounded-md border border-neutral-100 p-3 text-neutral-100 focus:ring-2 focus:ring-blue-500 focus:outline-none"
      />
    </div>
  );
}
