import { Outlet } from 'react-router';
import Sidebar from '../components/sidebar';

export default function sidebarLayout() {
  return (
    <>
      <Sidebar />
      <div className="p-2 w-full h-full">
        <Outlet></Outlet>
      </div>
    </>
  );
}
