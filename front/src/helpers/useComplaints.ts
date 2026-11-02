import { useCallback, useEffect, useReducer, useRef, useState } from 'react';
import { ComplaintRequestError, type ComplaintsRepository } from './complaintsRepository';
import type {
  ComplaintDetail,
  ComplaintDraft,
  ComplaintFailure,
  ComplaintFilters,
  ComplaintScope,
  ComplaintSummary,
} from '../types/Complaint';

const PAGE_SIZE = 20;
interface State {
  items: ComplaintSummary[];
  offset: number;
  hasMore: boolean;
  listLoading: boolean;
  listError: ComplaintFailure | null;
  detail: ComplaintDetail | null;
  selectedId: string | null;
  detailLoading: boolean;
  detailError: ComplaintFailure | null;
  pending: 'create' | 'respond' | 'status' | null;
  mutationError: ComplaintFailure | null;
  notice: 'created' | 'responded' | 'statusChanged' | null;
}
type Action =
  | { type: 'patch'; patch: Partial<State> }
  | { type: 'page'; rows: ComplaintSummary[]; append: boolean; offset: number };
const initial: State = {
  items: [],
  offset: 0,
  hasMore: false,
  listLoading: true,
  listError: null,
  detail: null,
  selectedId: null,
  detailLoading: false,
  detailError: null,
  pending: null,
  mutationError: null,
  notice: null,
};
function reducer(state: State, action: Action): State {
  if (action.type === 'patch') return { ...state, ...action.patch };
  const all = action.append ? [...state.items, ...action.rows] : action.rows;
  const byId = new Map(all.map((item) => [item.id, item]));
  return {
    ...state,
    items: [...byId.values()],
    offset: action.offset + action.rows.length,
    hasMore: action.rows.length === PAGE_SIZE,
    listLoading: false,
    listError: null,
  };
}
function reason(error: unknown): ComplaintFailure {
  return error instanceof ComplaintRequestError ? error.reason : 'server';
}

export default function useComplaints(
  repository: ComplaintsRepository,
  onUnauthorized: () => void,
) {
  const [state, dispatch] = useReducer(reducer, initial);
  const [scope, setScopeState] = useState<ComplaintScope>('mine');
  const [filters, setFiltersState] = useState<ComplaintFilters>({ status: '', category: '' });
  const mounted = useRef(false);
  const listGeneration = useRef(0);
  const detailGeneration = useRef(0);
  const mutationLocked = useRef(false);
  const selection = useRef<string | null>(null);
  const active = useCallback(() => mounted.current, []);
  const patch = useCallback(
    (values: Partial<State>) => dispatch({ type: 'patch', patch: values }),
    [],
  );
  const handleFailure = useCallback(
    (error: unknown) => {
      const failure = reason(error);
      if (failure === 'unauthorized') onUnauthorized();
      return failure;
    },
    [onUnauthorized],
  );

  useEffect(() => {
    const lists = listGeneration;
    const details = detailGeneration;
    mounted.current = true;
    return () => {
      mounted.current = false;
      lists.current++;
      details.current++;
    };
  }, []);

  const loadPage = useCallback(
    async (offset = 0, append = false) => {
      const generation = ++listGeneration.current;
      if (!active()) return;
      patch({
        listLoading: true,
        listError: null,
        ...(!append ? { offset: 0, hasMore: false } : {}),
      });
      try {
        const rows = await repository.list(scope, filters, offset, PAGE_SIZE);
        if (!active() || generation !== listGeneration.current) return;
        dispatch({ type: 'page', rows, append, offset });
      } catch (error) {
        if (active() && generation === listGeneration.current)
          patch({ listLoading: false, listError: handleFailure(error) });
      }
    },
    [active, filters, handleFailure, patch, repository, scope],
  );

  useEffect(() => {
    const generation = listGeneration;
    void loadPage();
    return () => {
      generation.current++;
    };
  }, [loadPage]);

  const select = useCallback(
    async (id: string | null) => {
      if (mutationLocked.current || !active()) return;
      const generation = ++detailGeneration.current;
      selection.current = id;
      patch({
        selectedId: id,
        detail: null,
        detailLoading: Boolean(id),
        detailError: null,
        mutationError: null,
        notice: null,
      });
      if (!id) return;
      try {
        const result = await repository.getDetail(id);
        if (active() && generation === detailGeneration.current)
          patch({ detail: result, detailLoading: false });
      } catch (error) {
        if (active() && generation === detailGeneration.current)
          patch({ detailLoading: false, detailError: handleFailure(error) });
      }
    },
    [active, handleFailure, patch, repository],
  );

  const changeScope = useCallback(
    (next: ComplaintScope) => {
      if (mutationLocked.current) return;
      listGeneration.current++;
      detailGeneration.current++;
      selection.current = null;
      patch({
        items: [],
        offset: 0,
        hasMore: false,
        detail: null,
        selectedId: null,
        detailLoading: false,
        detailError: null,
        mutationError: null,
        notice: null,
      });
      setScopeState(next);
    },
    [patch],
  );
  const changeFilters = useCallback(
    (next: ComplaintFilters) => {
      if (mutationLocked.current) return;
      listGeneration.current++;
      detailGeneration.current++;
      selection.current = null;
      patch({
        items: [],
        offset: 0,
        hasMore: false,
        detail: null,
        selectedId: null,
        detailLoading: false,
        detailError: null,
        mutationError: null,
        notice: null,
      });
      setFiltersState(next);
    },
    [patch],
  );

  const mutate = useCallback(
    async (
      kind: NonNullable<State['pending']>,
      operation: () => Promise<ComplaintDetail>,
      selectedId: string | null,
    ) => {
      if (
        mutationLocked.current ||
        !active() ||
        (selectedId !== null && selection.current !== selectedId)
      )
        return false;
      mutationLocked.current = true;
      // Reads started before a mutation must never replace its confirmed result.
      listGeneration.current++;
      detailGeneration.current++;
      patch({
        pending: kind,
        mutationError: null,
        notice: null,
        detailLoading: false,
        listLoading: false,
      });
      try {
        const result = await operation();
        if (!active()) return false;
        selection.current = result.id;
        patch({
          detail: result,
          selectedId: result.id,
          detailError: null,
          notice:
            kind === 'create' ? 'created' : kind === 'respond' ? 'responded' : 'statusChanged',
        });
        void loadPage();
        return true;
      } catch (error) {
        if (!active()) return false;
        const failure = handleFailure(error);
        patch({ mutationError: failure });
        // Conflicts and uncertain writes are reconciled by reads, never by retrying a write.
        if (
          failure === 'conflict' ||
          failure === 'responseRequired' ||
          failure === 'closed' ||
          failure === 'network'
        ) {
          void loadPage();
          if (selectedId) {
            const generation = ++detailGeneration.current;
            try {
              const result = await repository.getDetail(selectedId);
              if (active() && generation === detailGeneration.current) patch({ detail: result });
            } catch (readError) {
              if (active()) patch({ detailError: handleFailure(readError) });
            }
          }
        }
        return false;
      } finally {
        mutationLocked.current = false;
        if (active()) patch({ pending: null });
      }
    },
    [active, handleFailure, loadPage, patch, repository],
  );

  return {
    ...state,
    scope,
    filters,
    setScope: changeScope,
    setFilters: changeFilters,
    select,
    reload: () => loadPage(),
    loadMore: () =>
      state.hasMore && !state.listLoading ? loadPage(state.offset, true) : Promise.resolve(),
    create: (draft: ComplaintDraft) => mutate('create', () => repository.create(draft), null),
    respond: (id: string, message: string) =>
      mutate('respond', () => repository.respond(id, message), id),
    changeStatus: (id: string, nextStatus: 'em_analise' | 'encerrada') =>
      mutate('status', () => repository.changeStatus(id, nextStatus), id),
    dismissNotice: () => patch({ notice: null }),
  };
}
