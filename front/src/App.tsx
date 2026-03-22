import "./App.css";
import { BrowserRouter, Link, Route, Routes } from "react-router";
import Home from "./views/Home";
import Residents from "./views/Residents";

function App() {
  return (
    <BrowserRouter>
      <nav>
        <Link to="/">Home</Link>
        <Link to="/residents">Residents</Link>
      </nav>
      <div className="content">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/residents" element={<Residents />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
