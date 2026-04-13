import { BrowserRouter, Navigate, Route, Routes } from 'react-router';
import routes from './routes';
import SidebarLayout from './layouts/sidebarLayout';
import { ThemeProvider } from './contexts/ThemeProvider';
import type { RouteConfig } from './routes/route';
import { ToastProvider } from './components/Toast';

function CreateRouteEntry(r: RouteConfig) {
  return <Route path={r.path} element={<r.viewComponent />} key={r.path} />;
}

function App() {
  const sidebarViews = routes.filter((r) => r.layout == 'sidebar').map(CreateRouteEntry);

  const defaultViews = routes.filter((r) => r.layout == 'none').map(CreateRouteEntry);

  return (
    <ThemeProvider>
      <ToastProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Navigate to="/login" replace />} />
            <Route>{defaultViews}</Route>
            <Route element={<SidebarLayout />}>{sidebarViews}</Route>
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </ThemeProvider>
  );
}
export default App;
