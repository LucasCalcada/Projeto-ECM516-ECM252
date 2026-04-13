import { Outlet } from 'react-router';
import Sidebar from '../components/sidebar';

export default function sidebarLayout() {
  return (
    <>
      <Sidebar />
      <div className="h-full w-full p-2">
        <Outlet></Outlet>
      </div>
    </>
  );
}
