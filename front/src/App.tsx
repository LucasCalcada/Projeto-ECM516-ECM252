import { BrowserRouter, Route, Routes } from "react-router";
import routes from "./routes";
import Sidebar from "./components/sidebar";

function AppRoutes() {
  return (
    <Routes>
      {routes.map((r) => (
        <Route path={r.path} element={<r.viewComponent />} key={r.path} />
      ))}
    </Routes>
  );
}

function App() {
  return (
    <BrowserRouter>
      <Sidebar />
      <div className="content">
        <AppRoutes />
      </div>
    </BrowserRouter>
  );
}

export default App;
