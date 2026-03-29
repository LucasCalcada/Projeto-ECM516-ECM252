import { BrowserRouter, Navigate, Route, Routes } from 'react-router';
import routes from './routes';
import SidebarLayout from './layouts/sidebarLayout';
import type { RouteConfig } from './routes/route';

function CreateRouteEntry(r: RouteConfig) {
  return <Route path={r.path} element={<r.viewComponent />} key={r.path} />;
}

function App() {
  const sidebarViews = routes.filter((r) => r.layout == 'sidebar').map(CreateRouteEntry);

  const defaultViews = routes.filter((r) => r.layout == 'none').map(CreateRouteEntry);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route>{defaultViews}</Route>
        <Route element={<SidebarLayout />}>{sidebarViews}</Route>
      </Routes>
    </BrowserRouter>
  );
}
export default App;
