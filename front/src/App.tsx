import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router';
import routes from './routes';
import SidebarLayout from './layouts/sidebarLayout';
import type { RouteConfig } from './routes/route';
import { ToastProvider } from './components/Toast';

function CreateRouteEntry(r: RouteConfig) {
  return <Route path={r.path} element={<r.viewComponent />} key={r.path} />;
}

function RequireAccountAuth() {
  if (!localStorage.getItem('accountToken')) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}

function RequireUserAuth() {
  if (!localStorage.getItem('accountToken')) {
    return <Navigate to="/login" replace />;
  }

  if (!localStorage.getItem('userToken')) {
    return <Navigate to="/buildingSelector" replace />;
  }

  return <Outlet />;
}

function App() {
  const sidebarViews = routes.filter((r) => r.layout == 'sidebar').map(CreateRouteEntry);

  const publicViews = routes
    .filter((r) => r.layout == 'none' && r.path !== '/buildingSelector')
    .map(CreateRouteEntry);

  const accountViews = routes.filter((r) => r.path === '/buildingSelector').map(CreateRouteEntry);

  return (
    <ToastProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route>{publicViews}</Route>
          <Route element={<RequireAccountAuth />}>{accountViews}</Route>
          <Route element={<RequireUserAuth />}>
            <Route element={<SidebarLayout />}>{sidebarViews}</Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </ToastProvider>
  );
}
export default App;
