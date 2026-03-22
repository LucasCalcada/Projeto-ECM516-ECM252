import React from 'react';

// Aqui dizemos ao TypeScript o que esse componente aceita receber
interface TextFieldProps {
  id: string;
  label: string;
  type: string;
  value: string; 
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void; // A função que atualiza o estado
  placeholder: string;
}

export default function TextField({ id, label, type, value, onChange, placeholder }: TextFieldProps) {
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
        className="p-3 text-neutral-100 border border-neutral-100 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
    </div>
  );
}