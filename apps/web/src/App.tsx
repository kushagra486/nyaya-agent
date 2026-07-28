import { useState } from "react";
import { useAuth } from "./lib/auth";
import { DisclaimerBanner, SiteHeader, SiteFooter } from "./components/Chrome";
import { Correlator } from "./components/Correlator";
import { CaseAnalysis } from "./components/CaseAnalysis";
import { BrowseTable } from "./components/BrowseTable";
import { AuthScreen } from "./screens/AuthScreen";
import { DashboardScreen } from "./screens/DashboardScreen";
import { AnalysisScreen } from "./screens/AnalysisScreen";
import { ChatScreen } from "./screens/ChatScreen";
import { LawyersScreen } from "./screens/LawyersScreen";

type AppView = "dashboard" | "analysis" | "chat" | "lawyers";

function App() {
  const { session, loading, user } = useAuth();
  const [showAuth, setShowAuth] = useState(false);
  const [view, setView] = useState<AppView>("dashboard");
  const [activeCaseId, setActiveCaseId] = useState<string | null>(null);

  if (loading) {
    return <div style={{ minHeight: "100vh" }} />;
  }

  // Signed-in experience: the full product (Dashboard / Analysis / Chat / Lawyers)
  if (session && user) {
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
    if (view === "lawyers") {
      return (
        <LawyersScreen
          userId={user.id}
          activeCaseId={activeCaseId}
          onBack={() => setView("dashboard")}
        />
      );
    }
    return (
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
