export interface StatuteRecord {
  id: number;
  group: "criminal" | "procedure" | "evidence";
  oldSection: string;
  oldAct: string;
  newSection: string;
  newAct: string;
  title: string;
  notes: string;
}

export const GROUP_LABEL: Record<StatuteRecord["group"], string> = {
  criminal: "IPC → BNS",
  procedure: "CrPC → BNSS",
  evidence: "Evidence Act → BSA",
};
