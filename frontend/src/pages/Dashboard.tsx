import { useAuth } from "@/context/AuthContext"
import { LogOut } from "lucide-react"

export default function Dashboard() {
  const { user, logout } = useAuth()

  return (
    <div className="min-h-screen bg-slate-950 text-white p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Polar Command Dashboard</h1>
          <p className="text-slate-400 text-sm">
            Welcome, {user?.fullName} ({user?.role})
          </p>
        </div>
        <button
          onClick={logout}
          className="flex items-center gap-2 bg-slate-800 hover:bg-slate-700 px-4 py-2 rounded-lg text-sm"
        >
          <LogOut size={16} />
          Logout
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
        <p className="text-slate-300">
          Authenticated successfully. Real KPI cards, charts, and the live map
          will be built here in Phase 2 once the expedition, cargo, and
          personnel modules exist.
        </p>
      </div>
    </div>
  )
}
