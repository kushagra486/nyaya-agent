import { useState } from "react";
import { useAuth } from "./lib/auth";
import { DisclaimerBanner, SiteHeader, SiteFooter } from "./components/Chrome";
import { BottomNav, type NavTab } from "./components/BottomNav";
import { Correlator } from "./components/Correlator";
import { CaseAnalysis } from "./components/CaseAnalysis";
import { BrowseTable } from "./components/BrowseTable";
import { AuthScreen } from "./screens/AuthScreen";
import { DashboardScreen } from "./screens/DashboardScreen";
import { AnalysisScreen } from "./screens/AnalysisScreen";
import { ChatScreen } from "./screens/ChatScreen";
import { LawyersScreen } from "./screens/LawyersScreen";
import { HistoryScreen } from "./screens/HistoryScreen";
import { ProfileScreen } from "./screens/ProfileScreen";

type AppView = "dashboard" | "analysis" | "chat" | "lawyers" | "history" | "profile";

const TAB_VIEWS: NavTab[] = ["dashboard", "lawyers", "history", "profile"];

function App() {
  const { session, loading, user } = useAuth();
  const [showAuth, setShowAuth] = useState(false);
  const [view, setView] = useState<AppView>("dashboard");
  const [activeCaseId, setActiveCaseId] = useState<string | null>(null);

  if (loading) {
    return <div style={{ minHeight: "100vh" }} />;
  }

  // Signed-in experience: the full product (Dashboard / Analysis / Chat / Lawyers / History / Profile)
  if (session && user) {
    // Drill-in screens: no bottom nav, back-arrow navigation instead
    if (view === "analysis" && activeCaseId) {
      return (
        <AnalysisScreen
          caseId={activeCaseId}
          onBack={() => setView("dashboard")}
          onOpenChat={() => setView("chat")}
        />
      );
    }
    if (view === "chat" && activeCaseId) {
      return (
        <ChatScreen
          caseId={activeCaseId}
          userId={user.id}
          onBack={() => setView("analysis")}
        />
      );
    }

    // Top-level tab screens: persistent bottom nav
    const activeTab: NavTab = TAB_VIEWS.includes(view as NavTab) ? (view as NavTab) : "dashboard";

    let screen;
    if (view === "lawyers") {
      screen = (
        <LawyersScreen
          userId={user.id}
          activeCaseId={activeCaseId}
          onBack={() => setView("dashboard")}
        />
      );
    } else if (view === "history") {
      screen = (
        <HistoryScreen
          userId={user.id}
          onOpenCase={(id) => {
            setActiveCaseId(id);
            setView("analysis");
          }}
        />
      );
    } else if (view === "profile") {
      screen = <ProfileScreen email={user.email ?? null} />;
    } else {
      screen = (
        <DashboardScreen
          userId={user.id}
          onOpenCase={(id) => {
            setActiveCaseId(id);
            setView("analysis");
          }}
          onOpenLawyers={() => setView("lawyers")}
        />
      );
    }

    return (
      <>
        {screen}
        <BottomNav active={activeTab} onNavigate={(tab) => setView(tab)} />
      </>
    );
  }

  // Signed-out: public marketing/tool page, or the auth screen
  if (showAuth) {
    return <AuthScreen />;
  }

  return (
    <>
      <DisclaimerBanner />
      <SiteHeader onSignIn={() => setShowAuth(true)} />
      <main>
        <div className="fade-in-up"><Correlator /></div>
        <div className="fade-in-up"><CaseAnalysis /></div>
        <div className="fade-in-up"><BrowseTable /></div>
      </main>
      <SiteFooter />
    </>
  );
}

export default App;
