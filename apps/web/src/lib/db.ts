import { supabase } from "./supabaseClient";
import type { CaseRecord, ConsultationRecord, LawyerRecord, MessageRecord } from "./dbTypes";

// --- Cases -----------------------------------------------------------------
export async function listCases(userId: string): Promise<CaseRecord[]> {
  const { data, error } = await supabase
    .from("cases")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function createCase(userId: string, title: string, rawDescription: string): Promise<CaseRecord> {
  const { data, error } = await supabase
    .from("cases")
    .insert({ user_id: userId, title, raw_description: rawDescription })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateCaseAnalysis(caseId: string, analysis: string): Promise<void> {
  const { error } = await supabase
    .from("cases")
    .update({ ai_analysis: analysis, status: "analyzed", updated_at: new Date().toISOString() })
    .eq("id", caseId);
  if (error) throw error;
}

export async function getCase(caseId: string): Promise<CaseRecord | null> {
  const { data, error } = await supabase.from("cases").select("*").eq("id", caseId).single();
  if (error) throw error;
  return data;
}

// --- Messages (chat) ---------------------------------------------------------
export async function listMessages(caseId: string): Promise<MessageRecord[]> {
  const { data, error } = await supabase
    .from("messages")
    .select("*")
    .eq("case_id", caseId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

export async function addMessage(
  caseId: string,
  userId: string,
  role: "user" | "assistant",
  content: string
): Promise<MessageRecord> {
  const { data, error } = await supabase
    .from("messages")
    .insert({ case_id: caseId, user_id: userId, role, content })
    .select()
    .single();
  if (error) throw error;
  return data;
}

// --- Lawyers -------------------------------------------------------------------
export async function listLawyers(): Promise<LawyerRecord[]> {
  const { data, error } = await supabase.from("lawyers").select("*").order("experience_years", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

// --- Consultations -----------------------------------------------------------
export async function requestConsultation(
  caseId: string,
  userId: string,
  lawyerId: string,
  preferredTime: string
): Promise<ConsultationRecord> {
  const { data, error } = await supabase
    .from("consultations")
    .insert({ case_id: caseId, user_id: userId, lawyer_id: lawyerId, preferred_time: preferredTime })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function listConsultationsForCase(caseId: string): Promise<ConsultationRecord[]> {
  const { data, error } = await supabase.from("consultations").select("*").eq("case_id", caseId);
  if (error) throw error;
  return data ?? [];
}
