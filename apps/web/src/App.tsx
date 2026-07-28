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
        <Correlator />
        <CaseAnalysis />
        <BrowseTable />
      </main>
      <SiteFooter />
    </>
  );
}

export default App;
