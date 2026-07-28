import { useEffect, useRef, useState } from "react";
import { listMessages, addMessage, getCase } from "../lib/db";
import { chatWithAgent } from "../lib/groq";
import type { MessageRecord, CaseRecord } from "../lib/dbTypes";
import "./ChatScreen.css";

interface Props {
  caseId: string;
  userId: string;
  onBack: () => void;
}

const SUGGESTED = [
  "What documents do I need?",
  "What's the next step?",
  "Which court should I approach?",
];

export function ChatScreen({ caseId, userId, onBack }: Props) {
  const [record, setRecord] = useState<CaseRecord | null>(null);
  const [messages, setMessages] = useState<MessageRecord[]>([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  async function load() {
    const [c, msgs] = await Promise.all([getCase(caseId), listMessages(caseId)]);
    setRecord(c);
    setMessages(msgs);
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [caseId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send(text: string) {
    if (!text.trim() || sending || !record) return;
    setSending(true);
    setError(null);
    try {
      await addMessage(caseId, userId, "user", text.trim());
      setInput("");
      const refreshed = await listMessages(caseId);
      setMessages(refreshed);

      const history = refreshed.map((m) => ({ role: m.role, content: m.content }));
      const { raw } = await chatWithAgent(record.raw_description, history);
      await addMessage(caseId, userId, "assistant", raw);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Message failed to send.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="chat-screen">
      <header className="chat-header">
        <button type="button" className="analysis-back" onClick={onBack} aria-label="Back">
          ‹
        </button>
        <span className="chat-case-title">{record?.title ?? "Chat"}</span>
      </header>

      <div className="chat-messages">
        {messages.length === 0 && (
          <p className="chat-empty">
            Ask a follow-up about your case — the agent keeps the context from your last analysis.
          </p>
        )}
        {messages.map((m) => (
          <div key={m.id} className={`chat-bubble chat-bubble-${m.role}`}>
            <pre className="chat-bubble-text">{m.content}</pre>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      {error && <p className="chat-error">{error}</p>}

      <div className="chat-chip-row">
        {SUGGESTED.map((q) => (
          <button
            type="button"
            key={q}
            className="chat-chip"
            onClick={() => send(q)}
            disabled={sending}
          >
            {q}
          </button>
        ))}
      </div>

      <div className="chat-input-row">
        <button type="button" className="chat-icon-btn" disabled title="Coming soon" aria-label="Attach file">
          📎
        </button>
        <input
          className="chat-input"
          placeholder="Ask a follow-up…"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send(input)}
        />
        <button type="button" className="chat-icon-btn" disabled title="Coming soon" aria-label="Voice input">
          🎤
        </button>
        <button
          type="button"
          className="chat-send"
          onClick={() => send(input)}
          disabled={sending || !input.trim()}
          aria-label="Send"
        >
          {sending ? <span className="analyze-spinner" aria-hidden="true" /> : "→"}
        </button>
      </div>
    </div>
  );
}
