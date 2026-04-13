import Header from './header';
import SideNav from './sideNav';
import Options from './options';

function SideBar() {
  return (
    <div className="left-0 flex h-screen w-fit flex-col border-r-1 border-neutral-800 bg-neutral-900 p-2">
      <Header />
      <SideNav />
      <Options />
    </div>
  );
}

export default SideBar;
