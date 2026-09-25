'use client';

import { Bell, User } from 'lucide-react';
import { usePathname } from 'next/navigation';

export default function Header() {
  const pathname = usePathname();
  
  // Very basic title mapping based on pathname
  const getPageTitle = () => {
    if (pathname === '/') return 'Dashboard';
    if (pathname === '/settings') return 'Settings';
    return 'Werk Portal';
  };

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 sm:px-6 lg:px-8 shrink-0">
      {/* Mobile: empty space to push items right if sidebar toggle is elsewhere. Desktop: Page Title */}
      <div className="flex-1 flex items-center">
        <h2 className="text-lg font-semibold text-slate-800 hidden lg:block">
          {getPageTitle()}
        </h2>
      </div>
      
      {/* Right side actions */}
      <div className="flex items-center gap-4">
        <button className="text-slate-400 hover:text-slate-600 p-2 rounded-full hover:bg-gray-100 transition-colors relative">
          <Bell size={20} />
          {/* Unread indicator dot */}
          <span className="absolute top-2 right-2 w-2 h-2 bg-rose-500 rounded-full border border-white"></span>
        </button>
        
        <div className="h-8 w-8 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-700 border border-indigo-200 cursor-pointer hover:ring-2 hover:ring-indigo-500 hover:ring-offset-2 transition-all">
          <User size={16} />
        </div>
      </div>
    </header>
  );
}
