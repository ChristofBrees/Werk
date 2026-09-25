export default function Settings() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Settings</h1>
          <p className="text-slate-500 mt-1">Manage your platform preferences and configuration.</p>
        </div>
      </div>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-8 border-b border-gray-100">
          <h2 className="text-lg font-semibold text-slate-900 mb-4">Authentication & Access</h2>
          <div className="bg-blue-50 text-blue-800 p-4 rounded-lg border border-blue-100 text-sm">
            <p>Authentication, user roles, and access controls will be managed here in a future update.</p>
          </div>
        </div>
        
        <div className="p-8">
          <h2 className="text-lg font-semibold text-slate-900 mb-4">General Preferences</h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
              <div>
                <p className="font-medium text-slate-800">Timezone</p>
                <p className="text-sm text-slate-500">Set your local timezone for activity logs</p>
              </div>
              <div className="bg-gray-100 text-gray-400 px-4 py-2 rounded-md text-sm cursor-not-allowed">
                UTC (Default)
              </div>
            </div>
            
            <div className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
              <div>
                <p className="font-medium text-slate-800">Email Notifications</p>
                <p className="text-sm text-slate-500">Receive alerts for automation failures</p>
              </div>
              <div className="w-11 h-6 bg-gray-200 rounded-full relative opacity-50 cursor-not-allowed">
                <div className="absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
