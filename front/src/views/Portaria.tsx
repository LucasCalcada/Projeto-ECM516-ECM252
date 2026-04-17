import { type FormEvent, useMemo, useState } from 'react';
import {
  BellRing,
  CheckCircle2,
  ClipboardCheck,
  DoorOpen,
  PackageCheck,
  QrCode,
  ShieldCheck,
  Truck,
  UserCheck,
} from 'lucide-react';
import { accessEntryLogs, accessInvites, deliveryPackages } from '../mockedData/portaria';
import type {
  AccessEntryLog,
  AccessInvite,
  DeliveryPackage,
  DeliveryStatus,
  VisitStatus,
} from '../types/Portaria';

interface InviteForm {
  guestName: string;
  guestDocument: string;
  residentName: string;
  apartment: string;
  validUntil: string;
  reason: string;
}

interface DeliveryForm {
  residentName: string;
  apartment: string;
  carrier: string;
  description: string;
}

const initialInviteForm: InviteForm = {
  guestName: '',
  guestDocument: '',
  residentName: 'Joao Silva',
  apartment: 'Apto 41',
  validUntil: '2026-04-17T22:00',
  reason: '',
};

const initialDeliveryForm: DeliveryForm = {
  residentName: '',
  apartment: '',
  carrier: '',
  description: '',
};

const statusLabel: Record<DeliveryStatus, string> = {
  waiting: 'Aguardando chegada',
  arrived: 'Na portaria',
  notified: 'Morador avisado',
  delivered: 'Entregue',
};

const visitStatusLabel: Record<VisitStatus, string> = {
  active: 'Liberado',
  used: 'Entrada registrada',
  expired: 'Expirado',
};

function formatDateTime(value: string) {
  return new Date(value).toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function buildToken(form: InviteForm, count: number) {
  const guest = form.guestName.trim().split(' ')[0] || 'VISITA';
  const apartment = form.apartment.replace(/\D/g, '') || '000';
  return `PORT-${apartment}-${guest.toUpperCase()}-${String(count + 1).padStart(3, '0')}`;
}

function QrPreview({ token }: { token: string }) {
  const cells = useMemo(() => {
    const seed = token.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return Array.from({ length: 49 }, (_, index) => {
      const finder =
        (index < 14 && index % 7 < 2) ||
        (index % 7 > 4 && index < 14) ||
        (index > 34 && index % 7 < 2);
      return finder || (seed + index * 11) % 5 < 2;
    });
  }, [token]);

  return (
    <div className="grid aspect-square w-36 grid-cols-7 gap-1 rounded-lg bg-white p-3">
      {cells.map((filled, index) => (
        <span
          key={`${token}-${index}`}
          className={`rounded-sm ${filled ? 'bg-neutral-950' : 'bg-white'}`}
        />
      ))}
    </div>
  );
}

function deliveryTone(status: DeliveryStatus) {
  if (status === 'waiting') return 'border-yellow-700/60 bg-yellow-950/20 text-yellow-200';
  if (status === 'arrived') return 'border-cyan-700/60 bg-cyan-950/20 text-cyan-200';
  if (status === 'notified') return 'border-green-700/60 bg-green-950/20 text-green-200';
  return 'border-neutral-700 bg-neutral-900 text-neutral-300';
}

function visitTone(status: VisitStatus) {
  if (status === 'active') return 'border-green-800 bg-green-950/30 text-green-200';
  if (status === 'used') return 'border-cyan-800 bg-cyan-950/30 text-cyan-200';
  return 'border-neutral-700 bg-neutral-900 text-neutral-300';
}

export default function Portaria() {
  const [invites, setInvites] = useState<AccessInvite[]>(accessInvites);
  const [entries, setEntries] = useState<AccessEntryLog[]>(accessEntryLogs);
  const [deliveries, setDeliveries] = useState<DeliveryPackage[]>(deliveryPackages);
  const [selectedInviteId, setSelectedInviteId] = useState(accessInvites[0]?.id ?? '');
  const [inviteForm, setInviteForm] = useState<InviteForm>(initialInviteForm);
  const [deliveryForm, setDeliveryForm] = useState<DeliveryForm>(initialDeliveryForm);
  const [notification, setNotification] = useState('');

  const selectedInvite = invites.find((invite) => invite.id === selectedInviteId) ?? invites[0];
  const activeInvites = invites.filter((invite) => invite.status === 'active');

  function updateInvite<K extends keyof InviteForm>(key: K, value: InviteForm[K]) {
    setInviteForm((prev) => ({ ...prev, [key]: value }));
  }

  function updateDelivery<K extends keyof DeliveryForm>(key: K, value: DeliveryForm[K]) {
    setDeliveryForm((prev) => ({ ...prev, [key]: value }));
  }

  function createInvite(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!inviteForm.guestName || !inviteForm.residentName || !inviteForm.apartment) {
      setNotification('Preencha visitante, morador e apartamento para gerar o QR.');
      return;
    }

    const newInvite: AccessInvite = {
      id: `visit-${invites.length + 1}`,
      guestName: inviteForm.guestName.trim(),
      guestDocument: inviteForm.guestDocument.trim() || 'Documento nao informado',
      residentName: inviteForm.residentName.trim(),
      apartment: inviteForm.apartment.trim(),
      validUntil: inviteForm.validUntil,
      reason: inviteForm.reason.trim() || 'Visita autorizada',
      status: 'active',
      token: buildToken(inviteForm, invites.length),
    };

    setInvites((prev) => [newInvite, ...prev]);
    setSelectedInviteId(newInvite.id);
    setNotification(`QR gerado para ${newInvite.guestName}. A portaria ja consegue conferir.`);
    setInviteForm((prev) => ({ ...prev, guestName: '', guestDocument: '', reason: '' }));
  }

  function registerDelivery(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!deliveryForm.residentName || !deliveryForm.apartment || !deliveryForm.description) {
      setNotification('Informe morador, apartamento e descricao da entrega.');
      return;
    }

    const newDelivery: DeliveryPackage = {
      id: `pkg-${deliveries.length + 1}`,
      residentName: deliveryForm.residentName.trim(),
      apartment: deliveryForm.apartment.trim(),
      carrier: deliveryForm.carrier.trim() || 'Transportadora',
      description: deliveryForm.description.trim(),
      createdAt: new Date().toISOString(),
      status: 'waiting',
    };

    setDeliveries((prev) => [newDelivery, ...prev]);
    setDeliveryForm(initialDeliveryForm);
    setNotification(`Entrega cadastrada para ${newDelivery.residentName}.`);
  }

  function markArrived(id: string) {
    setDeliveries((prev) =>
      prev.map((delivery) => (delivery.id === id ? { ...delivery, status: 'notified' } : delivery)),
    );

    const delivery = deliveries.find((item) => item.id === id);
    if (delivery) {
      setNotification(`Notificacao enviada para ${delivery.residentName} no celular.`);
    }
  }

  function registerEntry(invite: AccessInvite) {
    const newEntry: AccessEntryLog = {
      id: `entry-${entries.length + 1}`,
      inviteId: invite.id,
      guestName: invite.guestName,
      guestDocument: invite.guestDocument,
      residentName: invite.residentName,
      apartment: invite.apartment,
      enteredAt: new Date().toISOString(),
      porterName: 'Portaria principal',
    };

    setEntries((prev) => [newEntry, ...prev]);
    setInvites((prev) =>
      prev.map((item) => (item.id === invite.id ? { ...item, status: 'used' } : item)),
    );
    setNotification(`Entrada registrada para ${invite.guestName} em ${invite.apartment}.`);
  }

  return (
    <div className="h-full overflow-auto p-4 md:p-8">
      <div className="mb-6 flex flex-col gap-2">
        <div className="flex items-center gap-2 text-cyan-300">
          <ShieldCheck size={22} />
          <span className="text-sm font-semibold tracking-wide uppercase">Portaria</span>
        </div>
        <h1 className="text-2xl font-bold text-neutral-100">Controle de acesso e entregas</h1>
        <p className="max-w-3xl text-neutral-400">
          Gere convites com QR para visitantes e acompanhe pacotes que chegam na portaria.
        </p>
      </div>

      {notification ? (
        <div className="mb-4 rounded-lg border border-cyan-800 bg-cyan-950/30 p-3 text-sm text-cyan-100">
          {notification}
        </div>
      ) : null}

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
          <div className="mb-4 flex items-center justify-between gap-3">
            <div>
              <h2 className="flex items-center gap-2 text-lg font-semibold text-neutral-100">
                <QrCode size={20} />
                Convite com QR
              </h2>
              <p className="text-sm text-neutral-400">
                O morador libera a visita antes dela chegar.
              </p>
            </div>
            <span className="rounded-full border border-green-800 bg-green-950/30 px-3 py-1 text-xs text-green-200">
              {activeInvites.length} ativos
            </span>
          </div>

          <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={createInvite}>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Visitante</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.guestName}
                onChange={(e) => updateInvite('guestName', e.target.value)}
                placeholder="Ex.: Bruno Almeida"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Documento</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.guestDocument}
                onChange={(e) => updateInvite('guestDocument', e.target.value)}
                placeholder="RG ou CPF"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Morador</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.residentName}
                onChange={(e) => updateInvite('residentName', e.target.value)}
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Apartamento</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.apartment}
                onChange={(e) => updateInvite('apartment', e.target.value)}
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Valido ate</span>
              <input
                type="datetime-local"
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.validUntil}
                onChange={(e) => updateInvite('validUntil', e.target.value)}
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Motivo</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={inviteForm.reason}
                onChange={(e) => updateInvite('reason', e.target.value)}
                placeholder="Ex.: jantar, reuniao, manutencao"
              />
            </label>
            <button
              type="submit"
              className="rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 md:col-span-2"
            >
              Gerar QR de acesso
            </button>
          </form>

          {selectedInvite ? (
            <div className="mt-4 grid grid-cols-1 gap-4 rounded-lg border border-neutral-800 bg-neutral-950 p-4 md:grid-cols-[auto_1fr]">
              <QrPreview token={selectedInvite.token} />
              <div className="min-w-0">
                <p className="mb-1 text-xs text-neutral-500 uppercase">Leitura na portaria</p>
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <h3 className="text-xl font-semibold text-neutral-100">
                      {selectedInvite.guestName}
                    </h3>
                    <p className="text-sm text-neutral-400">{selectedInvite.guestDocument}</p>
                  </div>
                  <span
                    className={`rounded-full border px-2 py-1 text-xs ${visitTone(selectedInvite.status)}`}
                  >
                    {visitStatusLabel[selectedInvite.status]}
                  </span>
                </div>
                <div className="mt-3 grid gap-2 text-sm text-neutral-300 sm:grid-cols-2">
                  <p>
                    <span className="text-neutral-500">Enviado por:</span>{' '}
                    {selectedInvite.residentName}
                  </p>
                  <p>
                    <span className="text-neutral-500">Apartamento:</span>{' '}
                    {selectedInvite.apartment}
                  </p>
                  <p>
                    <span className="text-neutral-500">Validade:</span>{' '}
                    {formatDateTime(selectedInvite.validUntil)}
                  </p>
                  <p>
                    <span className="text-neutral-500">Motivo:</span> {selectedInvite.reason}
                  </p>
                </div>
                <div className="mt-3 rounded-md border border-neutral-800 bg-neutral-900 p-2 text-xs text-neutral-400">
                  Token: <span className="font-mono text-neutral-100">{selectedInvite.token}</span>
                </div>
                <button
                  type="button"
                  className="mt-3 rounded-md bg-cyan-300 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-cyan-200 disabled:cursor-not-allowed disabled:bg-neutral-700 disabled:text-neutral-400"
                  onClick={() => registerEntry(selectedInvite)}
                  disabled={selectedInvite.status !== 'active'}
                >
                  <span className="inline-flex items-center gap-2">
                    <UserCheck size={16} />
                    Registrar entrada
                  </span>
                </button>
              </div>
            </div>
          ) : null}

          <div className="mt-4 space-y-2">
            {invites.map((invite) => (
              <button
                type="button"
                key={invite.id}
                onClick={() => setSelectedInviteId(invite.id)}
                className={`flex w-full items-center justify-between gap-3 rounded-md border p-3 text-left transition ${
                  selectedInviteId === invite.id
                    ? 'border-cyan-700 bg-cyan-950/20'
                    : 'border-neutral-800 bg-neutral-950 hover:bg-neutral-900'
                }`}
              >
                <span>
                  <span className="block font-medium text-neutral-100">{invite.guestName}</span>
                  <span className="text-sm text-neutral-400">
                    {invite.apartment} - {invite.residentName}
                  </span>
                </span>
                <span className="flex shrink-0 items-center gap-2">
                  <span
                    className={`rounded-full border px-2 py-1 text-xs ${visitTone(invite.status)}`}
                  >
                    {visitStatusLabel[invite.status]}
                  </span>
                  <DoorOpen size={18} className="text-cyan-300" />
                </span>
              </button>
            ))}
          </div>

          <div className="mt-4 rounded-lg border border-neutral-800 bg-neutral-950 p-3">
            <h3 className="mb-3 flex items-center gap-2 font-semibold text-neutral-100">
              <ClipboardCheck size={18} />
              Entradas registradas
            </h3>
            <div className="space-y-2">
              {entries.map((entry) => (
                <article
                  key={entry.id}
                  className="rounded-md border border-neutral-800 bg-neutral-900 p-3 text-sm"
                >
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <div>
                      <p className="font-medium text-neutral-100">{entry.guestName}</p>
                      <p className="text-neutral-500">{entry.guestDocument}</p>
                    </div>
                    <span className="text-xs text-neutral-500">
                      {formatDateTime(entry.enteredAt)}
                    </span>
                  </div>
                  <p className="mt-2 text-neutral-400">
                    Liberado por {entry.residentName} - {entry.apartment}
                  </p>
                  <p className="text-xs text-neutral-500">Registrado por {entry.porterName}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="rounded-lg border border-neutral-800 bg-neutral-900/40 p-4">
          <div className="mb-4 flex items-center justify-between gap-3">
            <div>
              <h2 className="flex items-center gap-2 text-lg font-semibold text-neutral-100">
                <PackageCheck size={20} />
                Pacotes e entregas
              </h2>
              <p className="text-sm text-neutral-400">
                A portaria registra a chegada e avisa o morador.
              </p>
            </div>
            <BellRing className="text-green-300" size={22} />
          </div>

          <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={registerDelivery}>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Morador</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={deliveryForm.residentName}
                onChange={(e) => updateDelivery('residentName', e.target.value)}
                placeholder="Nome do morador"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Apartamento</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={deliveryForm.apartment}
                onChange={(e) => updateDelivery('apartment', e.target.value)}
                placeholder="Apto 41"
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Transportadora</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={deliveryForm.carrier}
                onChange={(e) => updateDelivery('carrier', e.target.value)}
                placeholder="Correios, Amazon..."
              />
            </label>
            <label className="block">
              <span className="mb-1 block text-sm text-neutral-300">Descricao</span>
              <input
                className="w-full rounded-md border border-neutral-700 bg-neutral-950 px-3 py-2 text-sm"
                value={deliveryForm.description}
                onChange={(e) => updateDelivery('description', e.target.value)}
                placeholder="Caixa, envelope, sacola..."
              />
            </label>
            <button
              type="submit"
              className="rounded-md bg-neutral-100 px-3 py-2 text-sm font-semibold text-neutral-950 transition hover:bg-white md:col-span-2"
            >
              Cadastrar entrega esperada
            </button>
          </form>

          <div className="mt-4 space-y-3">
            {deliveries.map((delivery) => (
              <article
                key={delivery.id}
                className="rounded-lg border border-neutral-800 bg-neutral-950 p-3"
              >
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <h3 className="font-semibold text-neutral-100">{delivery.description}</h3>
                    <p className="text-sm text-neutral-400">
                      {delivery.residentName} - {delivery.apartment}
                    </p>
                  </div>
                  <span
                    className={`rounded-full border px-2 py-1 text-xs ${deliveryTone(delivery.status)}`}
                  >
                    {statusLabel[delivery.status]}
                  </span>
                </div>
                <div className="mt-3 flex flex-wrap items-center gap-3 text-sm text-neutral-400">
                  <span className="flex items-center gap-1">
                    <Truck size={15} /> {delivery.carrier}
                  </span>
                  <span>{formatDateTime(delivery.createdAt)}</span>
                </div>
                <div className="mt-3 flex flex-wrap gap-2">
                  <button
                    type="button"
                    className="rounded-md border border-green-800 px-3 py-1 text-sm text-green-200 transition hover:bg-green-950/40"
                    onClick={() => markArrived(delivery.id)}
                    disabled={delivery.status === 'notified' || delivery.status === 'delivered'}
                  >
                    <span className="inline-flex items-center gap-1">
                      <BellRing size={14} /> Avisar morador
                    </span>
                  </button>
                  <button
                    type="button"
                    className="rounded-md border border-neutral-700 px-3 py-1 text-sm text-neutral-300 transition hover:bg-neutral-900"
                    onClick={() =>
                      setDeliveries((prev) =>
                        prev.map((item) =>
                          item.id === delivery.id ? { ...item, status: 'delivered' } : item,
                        ),
                      )
                    }
                  >
                    <span className="inline-flex items-center gap-1">
                      <CheckCircle2 size={14} /> Marcar entregue
                    </span>
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
