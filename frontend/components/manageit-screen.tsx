"use client";

import { FormEvent, useMemo, useState } from "react";

type ManageItem = {
  id: string;
  name: string;
  type: string;
  status: "Active" | "Inactive";
  endpoint: string;
};

type ManageitScreenProps = {
  moduleId: string;
};

type FormState = {
  name: string;
  type: string;
  status: "Active" | "Inactive";
  endpoint: string;
};

const initialForm: FormState = {
  name: "",
  type: "",
  status: "Active",
  endpoint: "",
};

function EditIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 20h9" />
      <path d="M16.5 3.5a2.12 2.12 0 1 1 3 3L7 19l-4 1 1-4Z" />
    </svg>
  );
}

export function ManageitScreen({ moduleId }: ManageitScreenProps) {
  const [items, setItems] = useState<ManageItem[]>([
    {
      id: "1",
      name: "Core Worker",
      type: "Service",
      status: "Active",
      endpoint: "https://api.example.com/worker",
    },
    {
      id: "2",
      name: "Mail Sync",
      type: "Job",
      status: "Inactive",
      endpoint: "https://api.example.com/mail-sync",
    },
  ]);

  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(initialForm);

  const isEditing = useMemo(() => editingId != null, [editingId]);

  function openAddModal() {
    setEditingId(null);
    setForm(initialForm);
    setOpen(true);
  }

  function openEditModal(item: ManageItem) {
    setEditingId(item.id);
    setForm({
      name: item.name,
      type: item.type,
      status: item.status,
      endpoint: item.endpoint,
    });
    setOpen(true);
  }

  function closeModal() {
    setOpen(false);
    setEditingId(null);
    setForm(initialForm);
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (isEditing && editingId) {
      setItems((prev) =>
        prev.map((item) =>
          item.id === editingId
            ? {
                ...item,
                name: form.name.trim(),
                type: form.type.trim(),
                status: form.status,
                endpoint: form.endpoint.trim(),
              }
            : item,
        ),
      );
      closeModal();
      return;
    }

    const nextItem: ManageItem = {
      id: crypto.randomUUID(),
      name: form.name.trim(),
      type: form.type.trim(),
      status: form.status,
      endpoint: form.endpoint.trim(),
    };
    setItems((prev) => [nextItem, ...prev]);
    closeModal();
  }

  return (
    <main className="min-h-screen bg-stone-50 p-4 md:p-6">
      <section className="mx-auto max-w-5xl rounded-2xl border border-stone-300 bg-white p-4 md:p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-xs uppercase tracking-[0.08em] text-stone-500">Module</p>
            <h1 className="text-xl font-semibold text-stone-900">Manageit</h1>
            <p className="mt-1 text-sm text-stone-600">Module ID: {moduleId}</p>
          </div>

          <button
            onClick={openAddModal}
            className="rounded-md bg-emerald-700 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-800"
          >
            Add New
          </button>
        </div>

        <div className="mt-5 overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="border-b border-stone-200 text-xs uppercase tracking-[0.04em] text-stone-500">
              <tr>
                <th className="px-3 py-2">Name</th>
                <th className="px-3 py-2">Type</th>
                <th className="px-3 py-2">Status</th>
                <th className="px-3 py-2">Endpoint</th>
                <th className="px-3 py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.id} className="border-b border-stone-100">
                  <td className="px-3 py-3 font-medium text-stone-900">{item.name}</td>
                  <td className="px-3 py-3 text-stone-700">{item.type}</td>
                  <td className="px-3 py-3">
                    <span
                      className={`rounded-full px-2 py-1 text-xs ${
                        item.status === "Active"
                          ? "bg-emerald-100 text-emerald-800"
                          : "bg-stone-200 text-stone-700"
                      }`}
                    >
                      {item.status}
                    </span>
                  </td>
                  <td className="px-3 py-3 text-stone-700">{item.endpoint}</td>
                  <td className="px-3 py-3">
                    <div className="flex justify-end">
                      <button
                        onClick={() => openEditModal(item)}
                        className="inline-flex items-center gap-1 rounded-md border border-stone-300 px-2.5 py-1.5 text-xs text-stone-700 hover:bg-stone-100"
                        aria-label={`Edit ${item.name}`}
                        title="Edit"
                      >
                        <EditIcon />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {items.length === 0 ? (
                <tr>
                  <td className="px-3 py-8 text-center text-stone-500" colSpan={5}>
                    No records yet. Click Add New.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>

      {open ? (
        <div className="fixed inset-0 z-50 grid place-items-center bg-black/35 p-4">
          <div className="w-full max-w-lg rounded-2xl border border-stone-300 bg-white p-5 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-stone-900">
                {isEditing ? "Edit Item" : "Add New Item"}
              </h2>
              <button
                onClick={closeModal}
                className="rounded-md border border-stone-300 px-2 py-1 text-xs text-stone-700 hover:bg-stone-100"
              >
                Close
              </button>
            </div>

            <form onSubmit={onSubmit} className="grid gap-3">
              <label className="grid gap-1 text-sm">
                Name
                <input
                  required
                  value={form.name}
                  onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                  className="rounded-md border border-stone-300 px-3 py-2"
                  placeholder="Module name"
                />
              </label>

              <label className="grid gap-1 text-sm">
                Type
                <input
                  required
                  value={form.type}
                  onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}
                  className="rounded-md border border-stone-300 px-3 py-2"
                  placeholder="Service / Job / Plugin"
                />
              </label>

              <label className="grid gap-1 text-sm">
                Endpoint
                <input
                  required
                  value={form.endpoint}
                  onChange={(e) => setForm((f) => ({ ...f, endpoint: e.target.value }))}
                  className="rounded-md border border-stone-300 px-3 py-2"
                  placeholder="https://..."
                />
              </label>

              <label className="grid gap-1 text-sm">
                Status
                <select
                  value={form.status}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, status: e.target.value as "Active" | "Inactive" }))
                  }
                  className="rounded-md border border-stone-300 px-3 py-2"
                >
                  <option value="Active">Active</option>
                  <option value="Inactive">Inactive</option>
                </select>
              </label>

              <div className="mt-1 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={closeModal}
                  className="rounded-md border border-stone-300 px-3 py-2 text-sm text-stone-700 hover:bg-stone-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="rounded-md bg-emerald-700 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-800"
                >
                  {isEditing ? "Update" : "Create"}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </main>
  );
}
