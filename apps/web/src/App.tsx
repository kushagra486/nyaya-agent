import { DisclaimerBanner, SiteHeader, SiteFooter } from "./components/Chrome";
import { Correlator } from "./components/Correlator";
import { CaseAnalysis } from "./components/CaseAnalysis";
import { BrowseTable } from "./components/BrowseTable";

function App() {
  return (
    <>
      <DisclaimerBanner />
      <SiteHeader />
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
