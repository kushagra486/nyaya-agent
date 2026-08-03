// Hearing reminders :: email sender
// Meant to be called on a schedule (see .github/workflows/reminders-check.yml),
// not by the frontend directly - it's a write/side-effect operation.
//
// Uses Resend (free tier, no card required) for email. Set RESEND_API_KEY
// in Vercel env vars. The "from" address below (onboarding@resend.dev) is
// Resend's shared sender that works without verifying your own domain -
// fine to start with, but swap in a verified domain address for anything
// beyond testing (Resend dashboard -> Domains).

const SUPABASE_URL = "https://qojdhatypfuakhkkedar.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R";

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") return res.status(204).end();

  const providedSecret = req.headers["x-ingest-secret"] || req.query?.secret;
  if (process.env.INGEST_SECRET && providedSecret !== process.env.INGEST_SECRET) {
    return res.status(401).json({ error: "Invalid or missing ingest secret." });
  }

  const resendKey = process.env.RESEND_API_KEY;
  if (!resendKey) {
    return res.status(500).json({ error: "Server is missing RESEND_API_KEY. Set it in Vercel → Project Settings → Environment Variables." });
  }

  try {
    const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_due_reminders`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify({}),
    });
    if (!rpcRes.ok) {
      const body = await rpcRes.text().catch(() => "");
      return res.status(502).json({ error: `Supabase RPC error ${rpcRes.status}: ${body.slice(0, 300)}` });
    }
    const dueReminders = await rpcRes.json();

    const results = [];
    for (const reminder of dueReminders) {
      try {
        const emailRes = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${resendKey}`,
          },
          body: JSON.stringify({
            from: "Nyay Bharat <onboarding@resend.dev>",
            to: reminder.recipient_email,
            subject: `Reminder: upcoming hearing for "${reminder.case_title}"`,
            html: `<p>This is a reminder about your case <strong>${reminder.case_title}</strong>.</p>
                   <p>Log in to Nyay Bharat to review the latest analysis, chat with the agent, or find a lawyer.</p>
                   <p style="color:#888; font-size:12px;">This is an automated reminder, not legal advice.</p>`,
          }),
        });
        if (!emailRes.ok) {
          const body = await emailRes.text().catch(() => "");
          results.push({ reminder_id: reminder.reminder_id, ok: false, error: `Resend ${emailRes.status}: ${body.slice(0, 200)}` });
          continue;
        }

        await fetch(`${SUPABASE_URL}/rest/v1/rpc/mark_reminder_sent`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: SUPABASE_ANON_KEY,
            Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({ p_reminder_id: reminder.reminder_id }),
        });
        results.push({ reminder_id: reminder.reminder_id, ok: true });
      } catch (err) {
        results.push({ reminder_id: reminder.reminder_id, ok: false, error: err instanceof Error ? err.message : "Unknown error" });
      }
    }

    return res.status(200).json({ checked: dueReminders.length, results });
  } catch (err) {
    return res.status(500).json({ error: err instanceof Error ? err.message : "Unknown server error." });
  }
}
