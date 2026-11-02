import Header from './header';
import SideNav from './sideNav';
import Options from './options';

function SideBar() {
  return (
    <div className="flex h-full min-h-0 w-full flex-col justify-between gap-6 overflow-y-auto bg-neutral-900 p-2">
      <Header />
      <SideNav />
      <Options />
    </div>
  );
}

export default SideBar;
