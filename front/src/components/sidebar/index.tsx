import Header from './header';
import SideNav from './sideNav';
import Options from './options';

function SideBar() {
  return (
    <div className="flex flex-col left-0 w-fit h-screen bg-neutral-900 p-2 border-neutral-800 border-r-1">
      <Header />
      <SideNav />
      <Options />
    </div>
  );
}

export default SideBar;
