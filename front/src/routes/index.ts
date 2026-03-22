import { HomeIcon, UserRound } from "lucide-react";
import Home from "../views/Home";
import Residents from "../views/Residents";
import Login from "../views/Login";
import type { RouteConfig } from "./route";

const routes: RouteConfig[] = [
  {
    path: "/home",
    viewComponent: Home,
    layout: "sidebar",
    visible: true,
    display: {
      label: "Home",
      icon: HomeIcon,
    },
  },
  {
    path: "/residents",
    viewComponent: Residents,
    layout: "sidebar",
    visible: true,
    display: {
      label: "Residents",
      icon: UserRound,
    },
  },
  {
    path: "/login",
    viewComponent: Login,
    layout: "none",
    visible: false,
  },
];

export default routes;
