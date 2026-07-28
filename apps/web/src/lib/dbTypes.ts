export interface CaseRecord {
  id: string;
  user_id: string;
  title: string;
  raw_description: string;
  ai_analysis: string | null;
  status: "draft" | "analyzed";
  created_at: string;
  updated_at: string;
}

export interface MessageRecord {
  id: string;
  case_id: string;
  user_id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}

export interface LawyerRecord {
  id: string;
  name: string;
  photo_url: string | null;
  bar_council_reg_no: string;
  specializations: string[];
  court_practices: string[];
  experience_years: number;
  consultation_fee: number;
  is_verified: boolean;
}

export interface ConsultationRecord {
  id: string;
  case_id: string;
  user_id: string;
  lawyer_id: string;
  status: "pending" | "accepted" | "rejected" | "completed";
  preferred_time: string | null;
  created_at: string;
}
