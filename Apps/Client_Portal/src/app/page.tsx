import Link from 'next/link';
import { ArrowRight, Settings } from 'lucide-react';

export default function Dashboard() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-8">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Welcome to Werk</h1>
        <p className="text-lg text-slate-600 mb-8">AI-driven business automation platform</p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Quick Access Settings Card */}
          <Link href="/settings" className="block group">
            <div className="bg-indigo-50/50 rounded-lg p-6 border border-indigo-100 transition-all duration-200 hover:shadow-md hover:bg-indigo-50">
              <div className="flex items-center justify-between mb-4">
                <div className="bg-indigo-100 text-indigo-600 p-3 rounded-lg">
                  <Settings size={24} />
                </div>
                <ArrowRight size={20} className="text-indigo-400 group-hover:text-indigo-600 transition-colors" />
              </div>
              <h3 className="text-lg font-semibold text-slate-900 mb-1">Settings</h3>
              <p className="text-sm text-slate-600">Manage platform configuration</p>
            </div>
          </Link>
          
          {/* Placeholder Metrics 1 */}
          <div className="bg-white rounded-lg p-6 border border-gray-100 shadow-sm flex flex-col justify-center min-h-[140px]">
            <p className="text-sm font-medium text-slate-500 mb-1">Active Automations</p>
            <p className="text-3xl font-bold text-slate-900">12</p>
          </div>
          
          {/* Placeholder Metrics 2 */}
          <div className="bg-white rounded-lg p-6 border border-gray-100 shadow-sm flex flex-col justify-center min-h-[140px]">
            <p className="text-sm font-medium text-slate-500 mb-1">Tasks Completed (7d)</p>
            <p className="text-3xl font-bold text-slate-900">4,289</p>
          </div>
        </div>
      </div>
      
      {/* Activity Area Placeholder */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-8">
        <h2 className="text-xl font-semibold text-slate-900 mb-4">Recent Activity</h2>
        <div className="flex items-center justify-center h-48 border-2 border-dashed border-gray-200 rounded-lg bg-gray-50/50">
          <p className="text-slate-400 text-sm">No recent activity to display</p>
        </div>
      </div>
    </div>
  );
}
