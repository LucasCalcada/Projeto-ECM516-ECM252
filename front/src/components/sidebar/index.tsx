import Header from "./header";
import SideNav from "./sideNav";
import Options from "./options";

function SideBar() {
  return (
    <div className="flex flex-col left-0 absolute h-screen bg-neutral-900 p-2">
      <Header />
      <SideNav />
      <Options />
    </div>
  );
}

export default SideBar;
