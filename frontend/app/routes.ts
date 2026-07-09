import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("login", "routes/login.tsx"),
  route("register", "routes/register.tsx"),
  route("staff/login", "routes/staff-login.tsx"),
  route("branches/:id", "routes/branch-detail.tsx"),
  route("profile", "routes/profile.tsx"),
] satisfies RouteConfig;
