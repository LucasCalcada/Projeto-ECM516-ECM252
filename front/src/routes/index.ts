import { HomeIcon, UserRound } from "lucide-react";
import Home from "../views/Home";
import Residents from "../views/Residents";
import Login from "../views/Login";
import type { RouteConfig } from "./route";

const routes: RouteConfig[] = [
  {
    path: "/",
    visible: true,
    viewComponent: Home,
    display: {
      label: "Home",
      icon: HomeIcon,
    },
  },
  {
    path: "/residents",
    visible: false,
    viewComponent: Residents,
    display: {
      label: "Residents",
      icon: UserRound,
    },
  },
  {
    path: "/login",
    visible: false,
    viewComponent: Login,
  },

];

export default routes;
