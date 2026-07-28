import "./BottomNav.css";

export type NavTab = "dashboard" | "lawyers" | "history" | "profile";

interface Props {
  active: NavTab;
  onNavigate: (tab: NavTab) => void;
}

const TABS: { key: NavTab; label: string; icon: string }[] = [
  { key: "dashboard", label: "Dashboard", icon: "\uD83D\uDDC2" }, // card index
  { key: "lawyers", label: "Lawyers", icon: "\u2696\uFE0F" }, // scale
  { key: "history", label: "History", icon: "\uD83D\uDD52" }, // clock
  { key: "profile", label: "Profile", icon: "\uD83D\uDC64" }, // person
];

export function BottomNav({ active, onNavigate }: Props) {
  return (
    <nav className="bottom-nav" aria-label="Primary">
      {TABS.map((t) => (
        <button
          key={t.key}
          type="button"
          className={`bottom-nav-item ${active === t.key ? "bottom-nav-item-active" : ""}`}
          onClick={() => onNavigate(t.key)}
        >
          <span className="bottom-nav-icon" aria-hidden="true">{t.icon}</span>
          <span className="bottom-nav-label">{t.label}</span>
        </button>
      ))}
    </nav>
  );
}
