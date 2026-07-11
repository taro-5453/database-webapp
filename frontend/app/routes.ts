import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("login", "routes/login.tsx"),
  route("register", "routes/register.tsx"),
  route("staff/login", "routes/staff-login.tsx"),
  route("staff", "routes/staff-dashboard.tsx"),
  route("staff/queue", "routes/staff-queue.tsx"),
  route("staff/kitchen", "routes/staff-kitchen.tsx"),
  route("staff/menu", "routes/staff-menu.tsx"),
  route("staff/promotions", "routes/staff-promotions.tsx"),
  route("branches/:id", "routes/branch-detail.tsx"),
  route("profile", "routes/profile.tsx"),
  route("reserve", "routes/reserve.tsx"),
  route("session", "routes/find-session.tsx"),
  route("session/:id", "routes/dining-session.tsx"),
] satisfies RouteConfig;
