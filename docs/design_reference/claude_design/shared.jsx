// Shared.jsx — Screen frame, status bar, bottom nav, generic components

const StatusBar = ({ dark = false }) => {
  const c = dark ? '#fff' : '#17163B';
  return (
    <div className="slp-status">
      <span style={{ color: c }}>9:41</span>
      <div className="nub" style={{ background: dark ? '#0a0a16' : '#0a0a16' }}/>
      <div className="icons" style={{ color: c }}>
        <svg width="18" height="11" viewBox="0 0 19 12"><rect x="0" y="7.5" width="3.2" height="4.5" rx="0.7" fill={c}/><rect x="4.8" y="5" width="3.2" height="7" rx="0.7" fill={c}/><rect x="9.6" y="2.5" width="3.2" height="9.5" rx="0.7" fill={c}/><rect x="14.4" y="0" width="3.2" height="12" rx="0.7" fill={c}/></svg>
        <svg width="16" height="11" viewBox="0 0 17 12"><path d="M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z" fill={c}/><path d="M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z" fill={c}/><circle cx="8.5" cy="10.5" r="1.3" fill={c}/></svg>
        <svg width="25" height="12" viewBox="0 0 27 13"><rect x="0.5" y="0.5" width="23" height="12" rx="3.5" stroke={c} strokeOpacity="0.4" fill="none"/><rect x="2" y="2" width="20" height="9" rx="2" fill={c}/><path d="M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z" fill={c} fillOpacity="0.5"/></svg>
      </div>
    </div>
  );
};

const BottomNav = ({ active = 'home' }) => {
  const tabs = [
    { id: 'home', label: 'Home', icon: IHome },
    { id: 'tasks', label: 'Tasks', icon: IClipboard },
    { id: 'focus', label: 'Focus', icon: ITimer },
    { id: 'prayer', label: 'Prayer', icon: IMoon },
    { id: 'profile', label: 'Profile', icon: IUser },
  ];
  return (
    <div className="slp-nav">
      <div className="fab"><IPlus size={26} stroke={2.5}/></div>
      {tabs.map((t, i) => {
        // Skip middle slot for FAB visual balance? No — 5 tabs, FAB floats above.
        const Ico = t.icon;
        const isActive = t.id === active;
        return (
          <div key={t.id} className={`tab ${isActive ? 'active' : ''}`}>
            <Ico size={22} color={isActive ? 'var(--brand-primary)' : 'var(--text-muted)'} stroke={2}/>
            <span>{t.label}</span>
            {isActive && <div className="dot"/>}
          </div>
        );
      })}
    </div>
  );
};

const Screen = ({ children, nav = 'home', showNav = true, bg, statusDark = false }) => (
  <div className="slp-screen" style={bg ? { background: bg } : {}}>
    <StatusBar dark={statusDark}/>
    {children}
    {showNav && <BottomNav active={nav}/>}
  </div>
);

// Progress ring
const Ring = ({ value = 72, size = 110, stroke = 10, color = '#fff', track = 'rgba(255,255,255,0.25)', children, gradient }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c - (value / 100) * c;
  const gid = `g${Math.random().toString(36).slice(2,8)}`;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        {gradient && (
          <defs>
            <linearGradient id={gid} x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor={gradient[0]}/>
              <stop offset="100%" stopColor={gradient[1]}/>
            </linearGradient>
          </defs>
        )}
        <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={gradient ? `url(#${gid})` : color} strokeWidth={stroke} fill="none" strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off}/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        {children}
      </div>
    </div>
  );
};

// Header bar (back + title + action)
const TopBar = ({ title, right, onBack = true, subtitle }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0 18px' }}>
    {onBack && (
      <button style={{ width: 44, height: 44, borderRadius: 14, background: '#fff', border: '1px solid var(--border-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
        <IBack size={20} color="var(--text-primary)"/>
      </button>
    )}
    <div style={{ flex: 1 }}>
      <div className="h2">{title}</div>
      {subtitle && <div className="cap" style={{ marginTop: 2 }}>{subtitle}</div>}
    </div>
    {right}
  </div>
);

// Section header
const SectionHead = ({ title, action }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '20px 0 12px' }}>
    <div className="h3">{title}</div>
    {action && <div style={{ color: 'var(--brand-primary)', fontWeight: 700, fontSize: 13, display: 'flex', alignItems: 'center', gap: 4 }}>{action} <IArrowR size={14}/></div>}
  </div>
);

// Avatar fallback w/ initials
const Avatar = ({ initials = 'M', size = 44, src }) => (
  <div className="avatar" style={{ width: size, height: size, fontSize: size/2.8 }}>
    {src ? <img src={src} style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }}/> : initials}
  </div>
);

Object.assign(window, { StatusBar, BottomNav, Screen, Ring, TopBar, SectionHead, Avatar });
