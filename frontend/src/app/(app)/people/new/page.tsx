"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/PageHeader";
import { Button, ErrorBanner, Field, Input, TextArea } from "@/components/ui";
import { apiPost, ApiRequestError } from "@/lib/api";

export default function NewPersonPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [relationship, setRelationship] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await apiPost<{ id: string }>("/api/v1/people", {
        name: name.trim(),
        relationship: relationship || undefined,
        notes: notes || undefined,
      });
      router.replace(`/people/${res.data.id}`);
    } catch (err) {
      setError(
        err instanceof ApiRequestError ? err.message : "Could not save person.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader title="Add person" backHref="/people" />
      <ErrorBanner message={error} />
      <form onSubmit={onSubmit} className="space-y-4">
        <Field label="Name">
          <Input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Dad"
            autoFocus
          />
        </Field>
        <Field label="Relationship">
          <Input
            value={relationship}
            onChange={(e) => setRelationship(e.target.value)}
            placeholder="Father, Mother, Sibling…"
          />
        </Field>
        <Field label="Notes">
          <TextArea
            rows={2}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />
        </Field>
        <Button type="submit" className="w-full" loading={loading}>
          Save
        </Button>
      </form>
    </div>
  );
}
